module OpenDSA
  # number of exercises solved on the old OpenDSA system
  EXERCISES_SOLVED = 2305932

  # Directories that contain RST files with exercises in them that
  # we want to expose through LTI.
  # These directories are also used to determine which modules should be
  # made available as standalone modules exposed through LTI.
  STANDALONE_DIRECTORIES = {
    "AlgAnal" => "Algorithm Analysis",
    "SeniorAlgAnal" => "Advanced Analysis",
    "Background" => "Introduction and Mathematical Background",
    "Biography" => "Biographies",
    "Binary" => "Binary Trees",
    "BTRecurTutor" => "Binary Trees Recursion",
    "CT" => "Computational Thinking",
    "Design" => "Design",
    "Files" => "File Processing",
    "VisFormalLang" => "Formal Languages",
    "General" => "General Trees",
    "Graph" => "Graphs",
    "Hashing" => "Hashing",
    "Indexing" => "Indexing",
    "NP" => "Limits to Computing",
    "List" => "Linear Structures",
    "Bounds" => "Lower Bounds",
    "MemManage" => "Memory Management",
    "PointersJava" => "Pointers in Java",
    "PL" => "Programming Languages",
    "Tutorials" => "Programming Tutorials",
    "RecurTutor" => "Recursion",
    "Searching" => "Searching",
    "SearchStruct" => "Search Structures",
    "Sorting" => "Sorting",
    "Spatial" => "Spatial Data Structures",
    "Development" => "Under Development",
  }

  OPENDSA_DIRECTORY = File.join("public", "OpenDSA")

  # The directory where RST files are located
  RST_DIRECTORY = File.join(OPENDSA_DIRECTORY, "RST")

  # The directory where book configuration files are located
  BOOK_CONFIG_DIRECTORY = File.join(OPENDSA_DIRECTORY, "config")

  STANDALONE_MODULES_DIR_NAME = "StandaloneModules"
  STANDALONE_MODULES_DIRECTORY = File.join(OPENDSA_DIRECTORY, STANDALONE_MODULES_DIR_NAME)

  # A regular expression to match exercise/slideshow/frame directives in RST files
  EXERCISE_RE = Regexp.new("^(\.\. )(avembed|inlineav):: (([^\s]+\/)*([^\s.]*)(\.html)?) (ka|ss|pe|ff|ae)")

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
