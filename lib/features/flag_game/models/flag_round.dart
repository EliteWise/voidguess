List<int> buildAlternatingFlagRoundTypes({int count = 10}) {
  return List.generate(count, (index) => index % 2);
}
