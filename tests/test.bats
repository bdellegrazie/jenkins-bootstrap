@test "addition using bash" {
  result=$((2+2))
  [ "$result" -eq 4 ]
}

@test "subtraction using bash" {
  # deliberately wrong
  result="$((4-2))"
  [ "$result" -eq 4 ]
}
