variable "recursive_nameservers" {
  type = list(string)
  default = ["8.8.8.8:53", "1.1.1.1:53"]
}
