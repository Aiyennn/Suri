/// Centralized string constants for the app.
abstract final class AppStrings {
  static const String appName = 'Medical Triage';

  // Home
  static const String secureAi = 'Secure AI';
  static const String hipaaCompliant = 'HIPAA COMPLIANT';
  static const String aiHealthAssessment = 'AI Health Assessment';
  static const String homeDescription =
      'Analyze symptoms and medical images to understand health risks and recommended next steps.';
  static const String symptomChecker = 'Symptom Checker';
  static const String imageAnalysis = 'Image Analysis';
  static const String startAssessment = 'Start Assessment';
  static const String viewPreviousAssessments = 'View Previous Assessments';
  static const String poweredBy = 'Powered by Clinical Grade Intelligence';

  // Patient Details
  static const String patientDetails = 'Patient Details';
  static const String patientDetailsSubtitle =
      'Please provide basic information to start your assessment.';
  static const String age = 'Age';
  static const String enterAge = 'Enter age';
  static const String years = 'Years';
  static const String sexAtBirth = 'Sex';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';
  static const String currentSymptoms = 'Current Symptoms';
  static const String multiSelect = 'Multi-select';
  static const String searchSymptoms = 'Search or add symptom...';
  static const String addNew = '+ Add New';
  static const String howLong = 'How long have you had these?';
  static const String lessThan24h = '< 24h';
  static const String oneToThreeDays = '1-3 Days';
  static const String oneWeek = '1 Week';
  static const String moreThanOneWeek = '> 1 Week';
  static const String medicalHistory = 'Medical History (Optional)';
  static const String privacyNotice =
      'This information helps our AI provide more accurate guidance. All data is encrypted and handled according to medical privacy standards.';
  static const String continueText = 'Continue';

  // Upload Images
  static const String uploadMedicalImages = 'Upload Medical Images';
  static const String uploadSubtitle =
      'Select a category and upload clear photos for AI analysis. High-quality lighting improves accuracy.';
  static const String skin = 'Skin';
  static const String throat = 'Throat';
  static const String eye = 'Eye';
  static const String wound = 'Wound';
  static const String preview = 'Preview';
  static const String clearAll = 'Clear All';
  static const String add = 'Add';
  static const String hipaaEncryptionNote =
      'Secure, HIPAA-compliant encryption active for all medical media.';
  static const String analyzeHealthRisk = 'Analyze Health Risk';

  // Analyzing
  static const String analyzingData = 'Analyzing Data';
  static const String analyzingSubtitle =
      'AI engine is processing your symptoms and medical profile.';
  static const String patientInformation = 'Patient Information';
  static const String patientInfoDesc = 'Verified medical history and profile';
  static const String symptomAnalysis = 'Symptom Analysis Model';
  static const String symptomAnalysisDesc =
      'Cross-referencing reported conditions';
  static const String medicalImageModel = 'Medical Image Model';
  static const String medicalImageDesc =
      'Analyzing uploaded visuals and scans';
  static const String riskScoring = 'Risk Scoring Engine';
  static const String riskScoringDesc =
      'Calculating clinical priority levels';
  static const String knowledgeBase = 'Medical Knowledge Base';
  static const String knowledgeBaseDesc =
      'Consulting peer-reviewed literature';
  static const String llmExplanation = 'LLM Explanation Layer';
  static const String llmExplanationDesc =
      'Synthesizing personalized assessment';
  static const String generatingAssessment = 'Generating Assessment';
  static const String finalizing = 'Finalizing...';
  static const String synthesizingData =
      'Our AI is synthesizing complex clinical data...';
  static const String pleaseWait = 'Please Wait';

  // Results
  static const String assessmentReady = 'Assessment Ready';
  static const String urgencyLevel = 'URGENCY LEVEL';
  static const String aiConfidence = 'AI Confidence';
  static const String recommendedStep = 'Recommended Step';
  static const String findNearbyClinic = 'Find Nearby Clinic';
  static const String possibleConditions = 'Possible Conditions';
  static const String viewMoreResults = 'View more results';
  static const String aiReasoningSummary = 'AI Reasoning Summary';
  static const String immediateSelfCare = 'IMMEDIATE SELF-CARE';
  static const String saveAssessment = 'Save Assessment';
  static const String bookConsult = 'Book Consult';
  static const String callEmergency = 'Call Emergency Services';

  // Bottom Nav
  static const String home = 'Home';
  static const String assessments = 'Assessments';
  static const String history = 'History';
  static const String profile = 'Profile';
}
