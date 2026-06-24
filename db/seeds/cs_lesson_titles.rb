# frozen_string_literal: true

# Spec-derived lesson titles for the Computer Science (OCR GCSE J277) topics.
# Each topic gets two lesson titles drawn from the relevant J277 sub topics so the
# seeded lessons describe real content rather than generic placeholders. Keyed by
# topic name; only applied to topics under the Computer Science subject.
#
# Source: app/assets/specifications/J277 Specification.pdf
CS_LESSON_TITLES = {
  '1-1 System Architecture' => ['The CPU and the Fetch–Decode–Execute Cycle',
                                'CPU Performance and Embedded Systems'],
  '1-2 Memory' => ['Primary Storage: RAM and ROM',
                   'Virtual Memory and Cache'],
  '1-3 Storage' => ['Secondary Storage: Optical, Magnetic and Solid State',
                    'Units of Data and File Compression'],
  '1-4 Wired  Wireless Networks' => ['Wired and Wireless Connections',
                                     'IP Addressing, MAC Addresses and Encryption'],
  '1-5 Topologies Protocols  Layers' => ['Network Types, Topologies and Hardware',
                                         'Protocols and the Concept of Layers'],
  '1-6 System Security' => ['Threats to Computer Systems and Networks',
                            'Preventing Network Vulnerabilities'],
  '1-7 System Software' => ['Operating Systems and Their Functions',
                            'Utility Software'],
  '1-8 Ethical Legal Cultural Environmental Concerns' => ['Ethical, Cultural and Environmental Impacts of Technology',
                                                          'Legislation and Software Licences'],
  '2-1 Algorithms' => ['Computational Thinking and Designing Algorithms',
                       'Searching and Sorting Algorithms'],
  '2-2 Programming Techniques' => ['Variables, Constructs and Operators',
                                   'Data Types, Arrays and Subprograms'],
  '2-3 Making Robust Programs' => ['Defensive Design and Input Validation',
                                   'Testing and Selecting Test Data'],
  '2-4 Computational Logic' => ['Logic Gates: AND, OR and NOT',
                                'Truth Tables and Logic Diagrams'],
  '2-5 Translators and Languages' => ['High-Level and Low-Level Languages',
                                      'Translators and the IDE'],
  '2-6 Binary Addition' => ['Adding Binary Numbers and Overflow Errors',
                            'Binary Shifts'],
  '2-6 Binary and Denary' => ['Converting Between Denary and Binary',
                              'Most and Least Significant Bits'],
  '2-6 Data Representation' => ['Representing Characters, Images and Sound in Binary',
                                'Character Sets, Colour Depth and Sample Rate'],
  '2-6 Hex and Binary' => ['Converting Between Binary and Hexadecimal',
                           'Why Hexadecimal is Used'],
  '2-6 Hex and Denary' => ['Converting Between Denary and Hexadecimal',
                           'Working with the Hex Range 00–FF'],
  'Question Lucky Dip' => ['Mixed Topic Quick-Fire Questions',
                           'Exam-Style Mixed Revision'],
  'Algorithms' => ['Computational Thinking and Algorithm Design',
                   'Searching and Sorting Algorithms'],
  'Networks' => ['Network Types, Topologies and Hardware',
                 'Protocols, Layers and Network Security'],
  'Programming' => ['Programming Fundamentals and Data Types',
                    'Robust Programs and Boolean Logic'],
  'Data' => ['Number Systems: Binary, Denary and Hexadecimal',
             'Data Representation: Characters, Images and Sound']
}.freeze
