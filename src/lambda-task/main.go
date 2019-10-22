package main

import (
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"log"
	"encoding/json"
	"os"
	"github.com/aws/aws-sdk-go/aws"
   	"github.com/aws/aws-sdk-go/aws/session"
 	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"gopkg.in/go-playground/validator.v9"
)

type Task struct {
    ID   int `json:"ID" validate:"required"`
    Name  string `json:"Name" validate:"required"`
}

var db = dynamodb.New(session.New(), aws.NewConfig().WithRegion(os.Getenv("region")))

func getItem() ([]byte, error) {
    input := &dynamodb.ScanInput{
        TableName: aws.String(os.Getenv("dynamo_table")),
    }

    result, err := db.Scan(input)
    if err != nil {
        return nil, err
    }

	tasks := []Task{}
    err = dynamodbattribute.UnmarshalListOfMaps (result.Items, &tasks)
    if err != nil {
        return nil, err
	}
	
	responseJSON, err := json.Marshal(tasks)

    return responseJSON, nil
}

func putItem(request events.APIGatewayProxyRequest) (error) {

	bodyRequest := Task{}
	err := json.Unmarshal([]byte(request.Body), &bodyRequest)
	if err != nil {
		log.Println("Got error unmarshalling request:", err)
		return err
	}

	v := validator.New()
	err = v.Struct(bodyRequest)
	if err != nil {
		log.Println("Got error during validation:", err)
		return err
		}

	task, err := dynamodbattribute.MarshalMap(bodyRequest)
    if err != nil {
		log.Println("Got error marshalling new item:", err)
		return  err
	}

	input := &dynamodb.PutItemInput{
        Item:      task,
        TableName: aws.String(os.Getenv("dynamo_table")),
	}
	
	_, err = db.PutItem(input)
    if err != nil {
		log.Println("Got error calling PutItem: ", err)
		return err
	}
	
	return nil
}

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Println("Incoming request is: ", request)
	if request.HTTPMethod == "GET" {
		response, err := getItem()
		if err != nil {
			log.Println("Got error calling GetItem: ", err)
			ApiResponse := events.APIGatewayProxyResponse{
				Body:       "got error calling GetItem",
				StatusCode: 500}
			return ApiResponse, nil
			}

		ApiResponse := events.APIGatewayProxyResponse{
			Body:      string(response),
			StatusCode: 200,
		}
		return ApiResponse, nil

	} else if request.HTTPMethod == "POST" {
		err := putItem(request)
		if err != nil {
			ApiResponse := events.APIGatewayProxyResponse{
				Body:       "got error calling PutItem",
				StatusCode: 500}
			return ApiResponse, nil
			}

		ApiResponse := events.APIGatewayProxyResponse{
			Body:       "OK: task added",
			StatusCode: 200,
		}	
		return ApiResponse, nil

	} else {
		log.Println("Method not allowed")
		ApiResponse := events.APIGatewayProxyResponse{
			Body:       "method not allowed",
			StatusCode: 405}
		return ApiResponse, nil
	}
}

func main() {
	lambda.Start(handler)
}
