-- ============================================================
-- SCHOOL MANAGEMENT SYSTEM DATABASE SCHEMA
-- High-Quality Example with Best Practices
-- ============================================================
-- Features:
-- - Student enrollment and management
-- - Course and class scheduling
-- - Grade tracking
-- - Teacher assignments
-- - Attendance tracking
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- PEOPLE
-- ============================================================

CREATE TABLE people (
    person_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT CHECK(gender IN ('M', 'F', 'Other', 'Prefer not to say')),
    email TEXT UNIQUE,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_people_name ON people(last_name, first_name);
CREATE INDEX idx_people_email ON people(email);

-- ============================================================
-- STUDENTS
-- ============================================================

CREATE TABLE students (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER NOT NULL UNIQUE,
    student_number TEXT NOT NULL UNIQUE,
    grade_level INTEGER NOT NULL CHECK(grade_level >= 1 AND grade_level <= 12),
    enrollment_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' 
        CHECK(status IN ('active', 'inactive', 'graduated', 'transferred', 'expelled')),
    graduation_year INTEGER,
    gpa REAL CHECK(gpa >= 0.0 AND gpa <= 4.0),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
);

CREATE INDEX idx_students_grade ON students(grade_level);
CREATE INDEX idx_students_status ON students(status);
CREATE INDEX idx_students_number ON students(student_number);

-- ============================================================
-- TEACHERS
-- ============================================================

CREATE TABLE teachers (
    teacher_id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER NOT NULL UNIQUE,
    employee_number TEXT NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    department TEXT,
    specialization TEXT,
    status TEXT NOT NULL DEFAULT 'active' 
        CHECK(status IN ('active', 'inactive', 'on_leave', 'retired')),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
);

CREATE INDEX idx_teachers_department ON teachers(department);
CREATE INDEX idx_teachers_status ON teachers(status);

-- ============================================================
-- COURSES AND CLASSES
-- ============================================================

CREATE TABLE courses (
    course_id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_code TEXT NOT NULL UNIQUE,
    course_name TEXT NOT NULL,
    description TEXT,
    department TEXT NOT NULL,
    credits INTEGER NOT NULL DEFAULT 1 CHECK(credits > 0),
    grade_level_min INTEGER CHECK(grade_level_min >= 1 AND grade_level_min <= 12),
    grade_level_max INTEGER CHECK(grade_level_max >= 1 AND grade_level_max <= 12),
    is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_courses_code ON courses(course_code);
CREATE INDEX idx_courses_department ON courses(department);

-- Academic terms/semesters
CREATE TABLE terms (
    term_id INTEGER PRIMARY KEY AUTOINCREMENT,
    term_name TEXT NOT NULL,  -- "Fall 2024", "Spring 2025"
    academic_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current INTEGER DEFAULT 0 CHECK(is_current IN (0, 1))
);

-- Specific class instances (course + term + teacher)
CREATE TABLE classes (
    class_id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_id INTEGER NOT NULL,
    term_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL,
    section TEXT,  -- "A", "B", "01", etc.
    room_number TEXT,
    schedule TEXT,  -- "MWF 9:00-10:00" or store separately
    max_students INTEGER DEFAULT 30,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (term_id) REFERENCES terms(term_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    UNIQUE(course_id, term_id, section)
);

CREATE INDEX idx_classes_course ON classes(course_id);
CREATE INDEX idx_classes_term ON classes(term_id);
CREATE INDEX idx_classes_teacher ON classes(teacher_id);

-- ============================================================
-- ENROLLMENTS
-- ============================================================

CREATE TABLE enrollments (
    enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'enrolled' 
        CHECK(status IN ('enrolled', 'dropped', 'completed', 'failed')),
    final_grade TEXT CHECK(final_grade IN ('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'I', 'W')),
    final_percentage REAL CHECK(final_percentage >= 0 AND final_percentage <= 100),
    dropped_date DATE,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    UNIQUE(student_id, class_id)
);

CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_class ON enrollments(class_id);

-- ============================================================
-- ASSIGNMENTS AND GRADES
-- ============================================================

CREATE TABLE assignments (
    assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_id INTEGER NOT NULL,
    assignment_name TEXT NOT NULL,
    description TEXT,
    assignment_type TEXT NOT NULL 
        CHECK(assignment_type IN ('homework', 'quiz', 'test', 'project', 'exam', 'participation')),
    max_points REAL NOT NULL CHECK(max_points > 0),
    weight REAL DEFAULT 1.0 CHECK(weight >= 0),  -- For weighted grading
    due_date DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE CASCADE
);

CREATE INDEX idx_assignments_class ON assignments(class_id);
CREATE INDEX idx_assignments_due ON assignments(due_date);

CREATE TABLE grades (
    grade_id INTEGER PRIMARY KEY AUTOINCREMENT,
    enrollment_id INTEGER NOT NULL,
    assignment_id INTEGER NOT NULL,
    points_earned REAL CHECK(points_earned >= 0),
    submitted_date DATETIME,
    graded_date DATETIME,
    notes TEXT,
    is_excused INTEGER DEFAULT 0 CHECK(is_excused IN (0, 1)),
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    FOREIGN KEY (assignment_id) REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    UNIQUE(enrollment_id, assignment_id)
);

CREATE INDEX idx_grades_enrollment ON grades(enrollment_id);
CREATE INDEX idx_grades_assignment ON grades(assignment_id);

-- ============================================================
-- ATTENDANCE
-- ============================================================

CREATE TABLE attendance (
    attendance_id INTEGER PRIMARY KEY AUTOINCREMENT,
    enrollment_id INTEGER NOT NULL,
    attendance_date DATE NOT NULL,
    status TEXT NOT NULL 
        CHECK(status IN ('present', 'absent', 'tardy', 'excused')),
    notes TEXT,
    recorded_by INTEGER,  -- teacher_id
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES teachers(teacher_id),
    UNIQUE(enrollment_id, attendance_date)
);

CREATE INDEX idx_attendance_enrollment ON attendance(enrollment_id);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);

-- ============================================================
-- PARENT/GUARDIAN
-- ============================================================

CREATE TABLE parents (
    parent_id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER NOT NULL UNIQUE,
    relationship TEXT NOT NULL 
        CHECK(relationship IN ('mother', 'father', 'guardian', 'other')),
    is_primary_contact INTEGER DEFAULT 0 CHECK(is_primary_contact IN (0, 1)),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
);

CREATE TABLE student_parents (
    student_id INTEGER NOT NULL,
    parent_id INTEGER NOT NULL,
    PRIMARY KEY (student_id, parent_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES parents(parent_id) ON DELETE CASCADE
);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update person timestamp
CREATE TRIGGER update_person_timestamp 
AFTER UPDATE ON people
FOR EACH ROW
BEGIN
    UPDATE people SET updated_at = CURRENT_TIMESTAMP 
    WHERE person_id = NEW.person_id;
END;

-- Calculate GPA when grades change (simplified version)
CREATE TRIGGER update_student_gpa 
AFTER UPDATE ON enrollments
FOR EACH ROW
WHEN NEW.final_grade IS NOT NULL
BEGIN
    UPDATE students 
    SET gpa = (
        SELECT AVG(
            CASE final_grade
                WHEN 'A+' THEN 4.0
                WHEN 'A' THEN 4.0
                WHEN 'A-' THEN 3.7
                WHEN 'B+' THEN 3.3
                WHEN 'B' THEN 3.0
                WHEN 'B-' THEN 2.7
                WHEN 'C+' THEN 2.3
                WHEN 'C' THEN 2.0
                WHEN 'C-' THEN 1.7
                WHEN 'D+' THEN 1.3
                WHEN 'D' THEN 1.0
                WHEN 'D-' THEN 0.7
                WHEN 'F' THEN 0.0
                ELSE NULL
            END
        )
        FROM enrollments
        WHERE student_id = NEW.student_id 
        AND status = 'completed'
        AND final_grade IS NOT NULL
    )
    WHERE student_id = NEW.student_id;
END;

-- ============================================================
-- VIEWS
-- ============================================================

-- Student information with contact details
CREATE VIEW student_details AS
SELECT 
    s.student_id,
    s.student_number,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.email,
    p.phone,
    s.grade_level,
    s.status,
    s.gpa,
    s.enrollment_date
FROM students s
JOIN people p ON s.person_id = p.person_id;

-- Class roster
CREATE VIEW class_roster AS
SELECT 
    c.class_id,
    co.course_code,
    co.course_name,
    c.section,
    t_person.first_name || ' ' || t_person.last_name as teacher_name,
    COUNT(e.enrollment_id) as enrolled_count,
    c.max_students
FROM classes c
JOIN courses co ON c.course_id = co.course_id
JOIN teachers t ON c.teacher_id = t.teacher_id
JOIN people t_person ON t.person_id = t_person.person_id
LEFT JOIN enrollments e ON c.class_id = e.class_id AND e.status = 'enrolled'
GROUP BY c.class_id;

-- ============================================================
-- SAMPLE QUERIES
-- ============================================================

-- Get student's current schedule
-- SELECT co.course_name, c.section, c.schedule, c.room_number,
--        p.first_name || ' ' || p.last_name as teacher
-- FROM enrollments e
-- JOIN classes c ON e.class_id = c.class_id
-- JOIN courses co ON c.course_id = co.course_id
-- JOIN teachers t ON c.teacher_id = t.teacher_id
-- JOIN people p ON t.person_id = p.person_id
-- WHERE e.student_id = ? AND e.status = 'enrolled';

-- Get student grades for a class
-- SELECT a.assignment_name, a.max_points, g.points_earned,
--        (g.points_earned / a.max_points * 100) as percentage
-- FROM grades g
-- JOIN assignments a ON g.assignment_id = a.assignment_id
-- JOIN enrollments e ON g.enrollment_id = e.enrollment_id
-- WHERE e.student_id = ? AND e.class_id = ?;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
