int fastAnswerScore(int timeSeconds) {
  if (timeSeconds < 3) return 1000;
  if (timeSeconds < 7) return 700;
  if (timeSeconds < 15) return 400;
  return 0;
}
