enum DetectionClasses { bacterial, blast, brownspot, tungro, nothing }

extension DetectionClassesExtension on DetectionClasses {
  String get label {
    switch (this) {
      case DetectionClasses.bacterial:
        return "Hama Bakteri";
      case DetectionClasses.blast:
        return "Jamur";
      case DetectionClasses.brownspot:
        return "Bintik Coklat";
      case DetectionClasses.tungro:
        return "Tungro";
      case DetectionClasses.nothing:
        return "Nothing";
    }
  }
}
