import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:http/http.dart' as http;

// Conditional imports for platform compatibility
import 'dart:io' if (dart.library.js) 'io_stub.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.js) 'io_stub.dart';

class PDFGenerationService {
  // Generate PDF for assessment result
  static Future<Uint8List> generateAssessmentPDF({
    required UserModel user,
    required AssessmentResult assessmentResult,
    Map<String, dynamic>? clinicEvaluation, // Optional clinic evaluation data
  }) async {
    // Debug validation
    _debugValidateAssessmentData(assessmentResult);
    
    final pdf = pw.Document();

    // Load Unicode-compatible fonts
    pw.Font? robotoFont;
    pw.Font? robotoBoldFont;
    pw.ThemeData theme = pw.ThemeData.base(); // Default theme
    
    try {
      // Try to load fonts from the system or use printing package built-in fonts
      robotoFont = await PdfGoogleFonts.notoSansRegular();
      robotoBoldFont = await PdfGoogleFonts.notoSansBold();
      
      // Set theme with Unicode fonts
      theme = pw.ThemeData.withFont(
        base: robotoFont,
        bold: robotoBoldFont,
      );
      print('✅ Unicode fonts loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load Unicode fonts, using default fonts: $e');
      // Keep the default theme if font loading fails
    }

    // Load assessment images (handle both local files and Cloudinary URLs)
    List<pw.ImageProvider> assessmentImages = [];
    for (String imagePath in assessmentResult.imageUrls) {
      try {
        Uint8List? imageBytes;
        
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          // Handle Cloudinary URL with web-compatible HTTP client
          print('Loading image from URL: $imagePath');
          try {
            final response = await http.get(Uri.parse(imagePath));
            
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
              print('✅ Loaded image from URL: $imagePath');
            } else {
              print('❌ Failed to load image from URL: $imagePath (Status: ${response.statusCode})');
            }
          } catch (e) {
            print('❌ HTTP error loading image from URL: $imagePath - $e');
          }
        } else if (!kIsWeb) {
          // Handle local file path (only for non-web platforms)
          try {
            final file = File(imagePath);
            if (await file.exists()) {
              imageBytes = await file.readAsBytes();
              print('✅ Loaded local image: $imagePath');
            } else {
              print('❌ Local file not found: $imagePath');
            }
          } catch (e) {
            print('❌ Error loading local file: $imagePath - $e');
          }
        } else {
          print('❌ Local file paths not supported on web platform: $imagePath');
        }
        
        if (imageBytes != null) {
          assessmentImages.add(pw.MemoryImage(imageBytes));
        }
      } catch (e) {
        print('❌ Error loading image $imagePath: $e');
      }
    }
    // Try loading the PawSense logo from assets (optional)
    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/img/pawsense_logo.png');
      logoBytes = data.buffer.asUint8List();
      print('✅ Loaded PawSense logo for PDF header');
    } catch (e) {
      // Fallback: try legacy logo.png
      try {
        final data = await rootBundle.load('assets/img/logo.png');
        logoBytes = data.buffer.asUint8List();
        print('✅ Loaded fallback logo for PDF header');
      } catch (e) {
        print('⚠️ No logo asset found for PDF header: $e');
        logoBytes = null;
      }
    }

    // Capture generation timestamp for footer
    final DateTime _generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        build: (pw.Context context) {
          return [
            // Header with PawSense title and optional logo
            _buildHeader(logoBytes),
            pw.SizedBox(height: 20),

            // User profile section
            _buildUserProfileSection(user),
            pw.SizedBox(height: 15),

            // Pet assessment details
            _buildPetAssessmentDetails(assessmentResult),
            pw.SizedBox(height: 15),

            // Assessment results
            _buildAssessmentResults(assessmentResult),
            pw.SizedBox(height: 15),

            // Assessment images section
            if (assessmentImages.isNotEmpty) ...[
              _buildAssessmentImagesSection(assessmentResult, assessmentImages),
              pw.SizedBox(height: 15),
            ],

            // Clinic Evaluation section (if provided) - MOVED TO LAST
            if (clinicEvaluation != null && _hasClinicEvaluationData(clinicEvaluation))
              ...[
                _buildClinicEvaluationSection(clinicEvaluation),
                pw.SizedBox(height: 20),
              ],

            // Disclaimer
            _buildDisclaimer(),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(context, _generatedAt);
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to device storage (platform-aware approach)
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // For web, use the system save dialog via printing package
      try {
        await Printing.layoutPdf(
          name: fileName,
          format: PdfPageFormat.a4,
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
        return 'PDF saved via browser';
      } catch (e) {
        print('Error saving PDF on web: $e');
        rethrow;
      }
    } else {
      // For mobile platforms only
      try {
        Directory directory;
        
        if (Platform.isAndroid) {
          // For Android, try to save to external storage first
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Create a Downloads folder in external storage
            directory = Directory('${externalDir.path}/Downloads');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            // Fallback to application documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          // For iOS, use documents directory
          directory = await getApplicationDocumentsDirectory();
        }
        
        final file = File('${directory.path}/$fileName.pdf');
        await file.writeAsBytes(pdfBytes);
        
        print('PDF saved to: ${file.path}');
        return file.path;
      } catch (e) {
        print('Error saving PDF on mobile: $e');
        rethrow;
      }
    }
  }

  // Share PDF (This will open system share dialog where user can choose to save to Downloads)
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$fileName.pdf',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }

  // Alternative method: Save PDF using system's save dialog
  static Future<void> saveWithSystemDialog(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        name: fileName,
        format: PdfPageFormat.a4,
        onLayout: (format) => pdfBytes,
      );
    } catch (e) {
      print('Error opening save dialog: $e');
      rethrow;
    }
  }

  // Print PDF
  static Future<void> printPDF(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print('Error printing PDF: $e');
      rethrow;
    }
  }

  // Preview PDF
  static Future<void> previewPDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print('Error previewing PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildHeader(Uint8List? logoBytes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null) ...[
            pw.Container(
              width: 72,
              height: 72,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
              ),
            ),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PawSense',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Pet Health Assessment Report',
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.blue600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildUserProfileSection(UserModel user) {
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'User Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Profile Name:', user.username),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Email:', user.email),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildInfoRow('Date:', formattedDate),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPetAssessmentDetails(AssessmentResult assessmentResult) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pet Assessment Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Pet Name:', assessmentResult.petName),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Type:', assessmentResult.petType),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Breed:', assessmentResult.petBreed),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Age:', '${assessmentResult.petAge} months'),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Weight:', '${assessmentResult.petWeight} kg'),
                  ],
                ),
              ),
            ],
          ),
          if (assessmentResult.symptoms.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            pw.Text(
              'Observed Symptoms:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 4,
              children: assessmentResult.symptoms.map((symptom) => 
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    symptom,
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.blue800),
                  ),
                ),
              ).toList(),
            ),
          ],
          if (assessmentResult.notes.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            _buildInfoRow('Additional Notes:', assessmentResult.notes),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentResults(AssessmentResult assessmentResult) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assessment Results',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          // Show detection results by image
          if (assessmentResult.detectionResults.isNotEmpty) ...[
            pw.Text(
              'Detection Results by Image (Highest Confidence Only):',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 10),
            ...assessmentResult.detectionResults.asMap().entries.map((entry) {
              final imageIndex = entry.key;
              final detectionResult = entry.value;
              
              // Get only the highest confidence detection for this image
              Detection? highestDetection;
              if (detectionResult.detections.isNotEmpty) {
                final sortedDetections = List<Detection>.from(detectionResult.detections);
                sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
                highestDetection = sortedDetections.first;
              }
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Image ${imageIndex + 1} Results:',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (highestDetection != null) ...[
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 4,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Text(
                                highestDetection.label,
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ),
                            pw.Text(
                              '${(highestDetection.confidence * 100).toStringAsFixed(1)}%',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue200,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'Highest',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.blue800,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      pw.Text(
                        'No detections found in this image',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            
            // Show overall analysis results if available
            if (assessmentResult.analysisResults.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text(
                'Overall Analysis Summary:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 10),
              ...assessmentResult.analysisResults.map((result) => 
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          result.condition,
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Text(
                        '${_validatePercentage(result.percentage).toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ],
          ] else if (assessmentResult.analysisResults.isNotEmpty) ...[
            pw.Text(
              'Analysis Results:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 10),
            ...assessmentResult.analysisResults.map((result) => 
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        result.condition,
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ),
                    pw.Text(
                      '${_validatePercentage(result.percentage).toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ] else ...[
            pw.Text(
              'No specific conditions detected in the analysis.',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentImagesSection(AssessmentResult assessmentResult, List<pw.ImageProvider> assessmentImages) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assessment Images',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Images analyzed: ${assessmentImages.length}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 15),
          
          // Display actual images in a grid
          if (assessmentImages.isNotEmpty) ...[
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: assessmentImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(8),
                              topRight: pw.Radius.circular(8),
                            ),
                          ),
                          child: pw.Image(
                            image,
                            fit: pw.BoxFit.cover,
                            width: 200,
                            height: 150,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(8),
                            bottomRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          'Image ${index + 1}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'No images available for display',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Check if clinic evaluation has any data
  static bool _hasClinicEvaluationData(Map<String, dynamic> clinicEvaluation) {
    final diagnosis = clinicEvaluation['diagnosis'] as String?;
    final treatment = clinicEvaluation['treatment'] as String?;
    final prescription = clinicEvaluation['prescription'] as String?;
    final clinicNotes = clinicEvaluation['clinicNotes'] as String?;
    
    return (diagnosis != null && diagnosis.trim().isNotEmpty) ||
           (treatment != null && treatment.trim().isNotEmpty) ||
           (prescription != null && prescription.trim().isNotEmpty) ||
           (clinicNotes != null && clinicNotes.trim().isNotEmpty);
  }

  // Build clinic evaluation section for PDF
  static pw.Widget _buildClinicEvaluationSection(Map<String, dynamic> clinicEvaluation) {
    final diagnosis = clinicEvaluation['diagnosis'] as String?;
    final treatment = clinicEvaluation['treatment'] as String?;
    final prescription = clinicEvaluation['prescription'] as String?;
    final clinicNotes = clinicEvaluation['clinicNotes'] as String?;
    final completedAt = clinicEvaluation['completedAt'] as DateTime?;
    final isFollowUp = clinicEvaluation['isFollowUp'] as bool? ?? false;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green300, width: 1.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isFollowUp ? 'Previous Visit - Clinic Evaluation' : 'Clinic Evaluation',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              if (completedAt != null)
                pw.SizedBox(height: 4),
              if (completedAt != null)
                pw.Text(
                  'Completed: ${_formatDateTime(completedAt)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.green700,
                  ),
                ),
            ],
          ),
          
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.green300, thickness: 0.6),
          pw.SizedBox(height: 10),
          
          // Evaluation details
          if (diagnosis != null && diagnosis.trim().isNotEmpty) ...[
            _buildEvaluationRow('Diagnosis', diagnosis),
            pw.SizedBox(height: 10),
          ],
          
          if (treatment != null && treatment.trim().isNotEmpty) ...[
            _buildEvaluationRow('Treatment', treatment),
            pw.SizedBox(height: 10),
          ],
          
          if (prescription != null && prescription.trim().isNotEmpty) ...[
            _buildEvaluationRow('Prescription', prescription),
            pw.SizedBox(height: 10),
          ],
          
          if (clinicNotes != null && clinicNotes.trim().isNotEmpty) ...[
            _buildEvaluationRow('Clinic Notes', clinicNotes),
          ],
        ],
      ),
    );
  }

  // Build evaluation row for clinic evaluation section
  static pw.Widget _buildEvaluationRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey800,
            lineSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // Format DateTime for display
  static String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Important Disclaimer',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'This is a preliminary differential analysis based on visual assessment using AI technology. '
            'The results should not be considered as a final diagnosis. For a confirmed diagnosis and '
            'proper treatment plan, please consult a licensed veterinarian immediately. PawSense is not '
            'responsible for any medical decisions made based on this assessment.',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.red700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, DateTime generatedAt) {
    final generatedStr = '${generatedAt.day.toString().padLeft(2, '0')}/${generatedAt.month.toString().padLeft(2, '0')}/${generatedAt.year} '
        '${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Generated: $generatedStr',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            ' | ',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            'Generated by PawSense - Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          ),
        ),
      ],
    );
  }

  // Helper method to validate percentage values and prevent infinity/NaN errors
  static double _validatePercentage(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) {
      print('Warning: Invalid percentage value detected: $percentage, using 0.0 instead');
      return 0.0;
    }
    return percentage.clamp(0.0, 100.0);
  }

  // Debug method to validate assessment data before PDF generation
  static void _debugValidateAssessmentData(AssessmentResult assessment) {
    print('=== PDF Generation Debug ===');
    print('Pet Name: ${assessment.petName}');
    print('Analysis Results Count: ${assessment.analysisResults.length}');
    
    for (int i = 0; i < assessment.analysisResults.length; i++) {
      final result = assessment.analysisResults[i];
      print('Result $i: ${result.condition} - ${result.percentage}%');
      if (result.percentage.isNaN || result.percentage.isInfinite) {
        print('WARNING: Invalid percentage detected in result $i');
      }
    }
    
    print('Detection Results Count: ${assessment.detectionResults.length}');
    print('Image URLs Count: ${assessment.imageUrls.length}');
    print('===========================');
  }
}