module OpenDSA
  # number of exercises solved on the old OpenDSA system
  EXERCISES_SOLVED = 2305932

  # Directories that contain RST files with exercises in them that
  # we want to expose through LTI
  EXERCISE_DIRECTORIES = {
    "AlgAnal": "Algorithm Analysis",
    "Background": "Introduction and Mathematical Background",
    "Binary": "Binary Trees",
    "Biography": "Biographies",
    "Bounds": "Lower Bounds",
    "BTRecurTutor": "Binary Trees Recursion",
    "CT": "Computational Thinking",
    "Design": "Design",
    "Files": "File Processing",
    "FormalLang": "Formal Languages",
    "General": "General Trees",
    "Graph": "Graphs",
    "Hashing": "Hashing",
    "Indexing": "Indexing",
    "List": "Linear Structures",
    "MemManage": "Memory Management",
    "NP": "Limits to Computing",
    "PL": "Programming Languages",
    "PointersJava": "Pointers in Java",
    "RecurTutor": "Recursion",
    "Searching": "Searching",
    "SearchStruct": "Search Structures",
    "SeniorAlgAnal": "Advanced Analysis",
    "Sorting": "Sorting",
    "Spatial": "Spatial Data Structures",
    "Tutorials": "Programming Tutorials",
    "Development": "Under Development",
  }

  # The directory where RST files are located
  RST_DIRECTORY = File.join("public", "OpenDSA", "RST")

  # A regular expression to match exercise/slideshow/frame directives in RST files
  EXERCISE_RE = Regexp.new("^(\.\. )(avembed|inlineav):: (([^\s]+\/)*([^\s.]*)(\.html)?) (ka|ss|pe|ff)")

  # A regular expression to match external tool directives in RST files
  EXTR_RE = Regexp.new("^(\.\. )(extrtoolembed:: '([^']+)')")

  # languages that OpenDSA has content for
  BOOK_LANGUAGES = {
    "en" => "English",
    "fr" => "Français",
    "pt" => "Português",
    "fi" => "Suomi",
    "sv" => "Svenska",
  }

  # coding languages OpenDSA has examples in
  CODE_LANGUAGES = {
    "Java": {
      "ext": [
        "java",
      ],
      "label": "Java",
      "lang": "java",
    },
    "Java_Generic": {
      "ext": [
        "java",
      ],
      "label": "Java (Generic)",
      "lang": "java",
    },
    "Processing": {
      "ext": [
        "pde",
      ],
      "label": "Processing",
      "lang": "java",
    },
    "C++": {
      "ext": [
        "cpp",
        "h",
      ],
      "label": "C++",
      "lang": "C++",
    },
    "C": {
      "ext": [
        "c",
        "h",
      ],
      "label": "C",
      "lang": "c",
    },
    "Pseudo": {
      "ext": [
        "txt",
      ],
      "label": "Pseudo Code",
      "lang": "pseudo",
    },
    "Python": {
      "ext": [
        "py",
      ],
      "label": "Python",
      "lang": "python",
    },
    "JavaScript": {
      "ext": [
        "js",
      ],
      "label": "JavaScript",
      "lang": "javascript",
    },
  }

  # the placeholder email for the OpenDSA account used when an
  # instructor uses the student view mode in Canvas
  STUDENT_VIEW_EMAIL = 'student_view@example.com'
end
