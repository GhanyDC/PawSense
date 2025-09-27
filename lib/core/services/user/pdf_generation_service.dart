import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';

class PDFGenerationService {
  // Generate PDF for assessment result
  static Future<Uint8List> generateAssessmentPDF({
    required UserModel user,
    required AssessmentResult assessmentResult,
  }) async {
    final pdf = pw.Document();

    // Load logo image (you can add this to assets)
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/img/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Logo not found, continuing without logo: $e');
    }

    // Load assessment images (for future implementation)
    // In a production app, you would load the actual images here
    for (String imageUrl in assessmentResult.imageUrls) {
      print('Assessment image available: $imageUrl');
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            // Header with logo and PawSense title
            _buildHeader(logoImage),
            pw.SizedBox(height: 30),

            // User profile section
            _buildUserProfileSection(user),
            pw.SizedBox(height: 25),

            // Pet assessment details
            _buildPetAssessmentDetails(assessmentResult),
            pw.SizedBox(height: 25),

            // Assessment results
            _buildAssessmentResults(assessmentResult),
            pw.SizedBox(height: 25),

            // Assessment images section
            if (assessmentResult.imageUrls.isNotEmpty)
              _buildAssessmentImagesSection(assessmentResult),

            pw.SizedBox(height: 30),

            // Disclaimer
            _buildDisclaimer(),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(context);
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to device storage (simplified approach)
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
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
      print('Error saving PDF: $e');
      rethrow;
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

  static pw.Widget _buildHeader(pw.ImageProvider? logoImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          if (logoImage != null) ...[
            pw.Image(logoImage, width: 60, height: 60),
            pw.SizedBox(width: 20),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PawSense',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Pet Health Assessment Report',
                  style: pw.TextStyle(
                    fontSize: 16,
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
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Duration:', assessmentResult.duration),
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
          if (assessmentResult.analysisResults.isNotEmpty) ...[
            pw.Text(
              'Differential Analysis:',
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
                      '${result.percentage.toStringAsFixed(1)}%',
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

  static pw.Widget _buildAssessmentImagesSection(AssessmentResult assessmentResult) {
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
            'Number of images analyzed: ${assessmentResult.imageUrls.length}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          // Note: In a real implementation, you would load and display the actual images
          // For now, we'll just list the image paths
          ...assessmentResult.imageUrls.asMap().entries.map((entry) => 
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                'Image ${entry.key + 1}: ${entry.value.split('/').last}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ).toList(),
        ],
      ),
    );
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

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Generated by PawSense - Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
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
}