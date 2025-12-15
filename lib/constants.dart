extension MapReverseLookup<K, V> on Map<K, V> {
  V? get(V valueToFind) {
    for (final entry in entries) {
      if (entry.value == valueToFind) {
        return entry.value;
      }
    }
    return null;
  }
}