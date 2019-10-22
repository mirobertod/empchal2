resource "aws_dynamodb_table" "tasks-dynamodb-table" {
  name = "Tasks"
  read_capacity = 5
  write_capacity = 5
  hash_key = "ID"
  range_key = "Name"

  attribute {
      name = "ID"
      type = "N"
    }
  attribute {
      name = "Name"
      type = "S"
    }
}
