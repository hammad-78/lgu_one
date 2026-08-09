// lib/screens/gpa_calculator_screen.dart
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────

class Course {
  String name;
  int creditHours;
  String grade;

  Course({
    this.name = '',
    this.creditHours = 3,
    this.grade = 'A',
  });
}

class Semester {
  String name;
  List<Course> courses; // For SGPA mode
  double? sgpa;         // For CGPA mode
  int creditHours;      // For CGPA mode

  Semester({required this.name, List<Course>? courses, this.sgpa, this.creditHours = 0})
      : courses = courses ?? [];
}

// ─────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  bool isCGPAMode = false;
  List<Semester> semesters = [Semester(name: 'Semester 1')];

  // What-If Calculator Controllers
  final TextEditingController _targetCGPAController = TextEditingController();
  final TextEditingController _remainingCreditsController = TextEditingController();

  // LGU Grading Scale (for SGPA mode only)
  static const List<String> _lguGrades = [
    'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F', 'W', 'I', 'Tr'
  ];

  static const List<int> _creditOptions = [1, 2, 3, 4];

  // ───────────────────────────────────────────────────────────────────
  // CALCULATION LOGIC
  // ───────────────────────────────────────────────────────────────────

  double _getGradePoints(String grade) {
    switch (grade) {
      case 'A': return 4.00;
      case 'A-': return 3.70;
      case 'B+': return 3.30;
      case 'B': return 3.00;
      case 'B-': return 2.70;
      case 'C+': return 2.30;
      case 'C': return 2.00;
      case 'C-': return 1.70;
      case 'D': return 1.00;
      case 'F': return 0.00;
      default: return 0.0; // W, I, Tr excluded
    }
  }

  bool _isExcludedGrade(String grade) => ['W', 'I', 'Tr'].contains(grade);

  // SGPA calculation (for SGPA mode only)
  double _calculateSGPA(List<Course> courses) {
    double totalPoints = 0.0;
    int totalCredits = 0;

    for (var course in courses) {
      if (!_isExcludedGrade(course.grade)) {
        totalPoints += _getGradePoints(course.grade) * course.creditHours;
        totalCredits += course.creditHours;
      }
    }

    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  // CGPA calculation (SGPA × Credits for each semester)
  double _calculateCGPA() {
    double totalPoints = 0.0;
    int totalCredits = 0;

    for (var semester in semesters) {
      if (semester.sgpa != null && semester.creditHours > 0) {
        totalPoints += semester.sgpa! * semester.creditHours;
        totalCredits += semester.creditHours;
      }
    }

    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  String _getAcademicStanding(double cgpa) {
    if (cgpa >= 3.70) return 'Honors Track 🏆';
    if (cgpa >= 3.00) return 'Good Standing ✅';
    if (cgpa >= 2.00) return 'Satisfactory ⚠️';
    return 'At Risk ❌';
  }

  double _calculateRequiredGPA() {
    if (_targetCGPAController.text.isEmpty || _remainingCreditsController.text.isEmpty) {
      return 0.0;
    }
    final targetCGPA = double.tryParse(_targetCGPAController.text) ?? 0.0;
    final remainingCredits = int.tryParse(_remainingCreditsController.text) ?? 0;

    if (remainingCredits == 0) return 0.0;

    final currentCGPA = _calculateCGPA();
    final completedCredits = semesters.fold<int>(0, (sum, sem) => sum + sem.creditHours);

    final requiredPoints = (targetCGPA * (completedCredits + remainingCredits)) -
        (currentCGPA * completedCredits);
    return requiredPoints / remainingCredits;
  }

  // ───────────────────────────────────────────────────────────────────
  // STATE MUTATORS
  // ───────────────────────────────────────────────────────────────────

  void _addCourse(int semesterIndex) {
    setState(() {
      semesters[semesterIndex].courses.add(Course());
    });
  }

  void _removeCourse(int semesterIndex, int courseIndex) {
    setState(() {
      semesters[semesterIndex].courses.removeAt(courseIndex);
    });
  }

  void _addSemester() {
    setState(() {
      semesters.add(Semester(name: 'Semester ${semesters.length + 1}'));
    });
  }

  void _removeSemester(int index) {
    if (semesters.length > 1) {
      setState(() {
        semesters.removeAt(index);
        for (int i = 0; i < semesters.length; i++) {
          semesters[i].name = 'Semester ${i + 1}';
        }
      });
    }
  }

  void _updateCourseName(int semesterIndex, int courseIndex, String value) {
    setState(() {
      semesters[semesterIndex].courses[courseIndex].name = value;
    });
  }

  void _updateCourseCredits(int semesterIndex, int courseIndex, int value) {
    setState(() {
      semesters[semesterIndex].courses[courseIndex].creditHours = value;
    });
  }

  void _updateCourseGrade(int semesterIndex, int courseIndex, String value) {
    setState(() {
      semesters[semesterIndex].courses[courseIndex].grade = value;
    });
  }

  void _updateSemesterSGPA(int semesterIndex, double? value) {
    setState(() {
      semesters[semesterIndex].sgpa = value;
    });
  }

  void _updateSemesterCredits(int semesterIndex, int value) {
    setState(() {
      semesters[semesterIndex].creditHours = value;
    });
  }

  // ───────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentCGPA = _calculateCGPA();
    final currentSGPA = semesters.isNotEmpty ? _calculateSGPA(semesters[0].courses) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LGU GPA Calculator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('SGPA', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Switch(
                        value: isCGPAMode,
                        onChanged: (value) => setState(() => isCGPAMode = value),
                      ),
                    ),
                    const Text('CGPA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Semester List (CGPA Mode) or Single Semester (SGPA Mode)
            if (isCGPAMode) ..._buildCGPASemesterList() else _buildSingleSemester(0),

            if (isCGPAMode) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Semester'),
                onPressed: _addSemester,
              ),
            ],

            const SizedBox(height: 24),

            // Results Card
            _buildResultsCard(currentSGPA, currentCGPA),

            const SizedBox(height: 24),

            // What-If Calculator
            _buildWhatIfSection(),

            const SizedBox(height: 24),

            // LGU Motto
            Text(
              'Nurturing the Future of Pakistan in an Excellent Environment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // CGPA MODE: Semester GPA + Credits (NO courses)
  // ───────────────────────────────────────────────────────────────────

  List<Widget> _buildCGPASemesterList() {
    return semesters.asMap().entries.map((entry) {
      final index = entry.key;
      final semester = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      semester.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (semester.sgpa != null)
                          Text(
                            'SGPA: ${semester.sgpa!.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (semesters.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _removeSemester(index),
                            tooltip: 'Remove Semester',
                          ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Semester GPA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) => _updateSemesterSGPA(index, double.tryParse(value)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Credit Hours',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) => _updateSemesterCredits(index, int.tryParse(value) ?? 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ───────────────────────────────────────────────────────────────────
  // SGPA MODE: Individual Courses (unchanged)
  // ───────────────────────────────────────────────────────────────────

  Widget _buildSingleSemester(int semesterIndex) {
    final semester = semesters[semesterIndex];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semester Courses',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(),
            ...semester.courses.asMap().entries.map((e) {
              final courseIndex = e.key;
              final course = e.value;
              return _buildCourseRow(semesterIndex, courseIndex, course);
            }),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Course'),
              onPressed: () => _addCourse(semesterIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseRow(int semesterIndex, int courseIndex, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Course Name (Optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => _updateCourseName(semesterIndex, courseIndex, value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: course.creditHours,
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: _creditOptions.map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                    onChanged: (value) {
                      if (value != null) _updateCourseCredits(semesterIndex, courseIndex, value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: course.grade,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _lguGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) {
                      if (value != null) _updateCourseGrade(semesterIndex, courseIndex, value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeCourse(semesterIndex, courseIndex),
                  tooltip: 'Remove Course',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // SHARED WIDGETS (unchanged)
  // ───────────────────────────────────────────────────────────────────

  Widget _buildResultsCard(double sgpa, double cgpa) {
    final displayGPA = isCGPAMode ? cgpa : sgpa;
    final standing = _getAcademicStanding(cgpa);

    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              isCGPAMode ? 'Cumulative GPA' : 'Semester GPA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // ✅ FIXED MAIN GPA TEXT
            Text(
              displayGPA.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber
                    : Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cgpa >= 3.0
                    ? Colors.green.withValues(alpha: 0.2)
                    : cgpa >= 2.0
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                standing,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cgpa >= 3.0
                      ? Colors.green[700]
                      : cgpa >= 2.0
                      ? Colors.orange[700]
                      : Colors.red[700],
                ),
              ),
            ),

            if (isCGPAMode) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // ✅ FIXED TEXT STYLE
              Text(
                'Total Semesters: ${semesters.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildWhatIfSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.auto_graph),
        title: const Text('What-If Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _targetCGPAController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target CGPA',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remainingCreditsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Remaining Credit Hours',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (_targetCGPAController.text.isNotEmpty && _remainingCreditsController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary),
                    ),
                    child: Column(
                      children: [
                        const Text('You need:', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${_calculateRequiredGPA().toStringAsFixed(2)} GPA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'in your remaining ${_remainingCreditsController.text} credit hours',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _targetCGPAController.dispose();
    _remainingCreditsController.dispose();
    super.dispose();
  }
}
