variable "function_name" {
  description = "The function name for the lambda"
  type        = string
}

variable "handler_name" {
  description = "The handler name for the function"
  type        = string
}

variable "lambda_env" {
  description = "The directory of the lambda python virtualenv"
  type        = string
  default     = "lambda_env"
}

variable "lambda_package_dir" {
  description = "The directory of the lambda package"
  type        = string
  default     = "lambda_package"
}

variable "region" {
  description = "The AWS region within which resources will be deployed"
  type        = string
}

variable "runtime" {
  description = "The runtime for the lambda function"
  type        = string
}

variable "source_code_dir" {
  description = "The location of the lambda source code"
  type        = string
}

variable "timeout" {
  description = "The timeout for the lambda function"
  type        = string
}
