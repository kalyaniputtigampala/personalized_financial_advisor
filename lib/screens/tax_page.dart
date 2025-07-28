import 'package:flutter/material.dart';
import 'dart:math';

class TaxPage extends StatefulWidget {
  const TaxPage({super.key});

  @override
  _TaxPageState createState() => _TaxPageState();
}

class _TaxPageState extends State<TaxPage> {
  // Income Controllers
  TextEditingController salaryController = TextEditingController();
  TextEditingController businessController = TextEditingController();
  TextEditingController professionalController = TextEditingController();
  TextEditingController rentController = TextEditingController();
  TextEditingController agricultureController = TextEditingController();
  TextEditingController savingsInterestController = TextEditingController();
  TextEditingController winningsController = TextEditingController();
  TextEditingController giftsController = TextEditingController();
  TextEditingController pfInterestController = TextEditingController();

  // Deduction Controllers
  TextEditingController employerNPSController = TextEditingController();
  TextEditingController agniVeerController = TextEditingController();
  TextEditingController familyPensionController = TextEditingController();
  TextEditingController houseInterestController = TextEditingController();
  TextEditingController transportAllowanceController = TextEditingController();
  TextEditingController gratuityController = TextEditingController();
  TextEditingController leaveEncashmentController = TextEditingController();
  TextEditingController vrsController = TextEditingController();
  TextEditingController taxPaidController = TextEditingController();

  // Selection Variables
  String? incomeType;
  bool isSeniorCitizen = false;
  bool isDisabled = false;
  bool hasFamilyPension = false;
  bool hasHouseLoan = false;

  // Tax Calculation Results
  double grossIncome = 0;
  double totalDeductions = 0;
  double taxableIncome = 0;
  double calculatedTax = 0;
  double finalTax = 0;
  double taxPaid = 0;
  double refundOrPay = 0;
  double agriculturalIncome = 0;
  double totalIncomeForRateCalculation = 0;
  bool showResults = false;
  bool showOnlyReport = false;

  @override
  void dispose() {
    salaryController.dispose();
    businessController.dispose();
    professionalController.dispose();
    rentController.dispose();
    agricultureController.dispose();
    savingsInterestController.dispose();
    winningsController.dispose();
    giftsController.dispose();
    pfInterestController.dispose();
    employerNPSController.dispose();
    agniVeerController.dispose();
    familyPensionController.dispose();
    houseInterestController.dispose();
    transportAllowanceController.dispose();
    gratuityController.dispose();
    leaveEncashmentController.dispose();
    vrsController.dispose();
    taxPaidController.dispose();
    super.dispose();
  }

  void resetForm() {
    // Clear all controllers
    salaryController.clear();
    businessController.clear();
    professionalController.clear();
    rentController.clear();
    agricultureController.clear();
    savingsInterestController.clear();
    winningsController.clear();
    giftsController.clear();
    pfInterestController.clear();
    employerNPSController.clear();
    agniVeerController.clear();
    familyPensionController.clear();
    houseInterestController.clear();
    transportAllowanceController.clear();
    gratuityController.clear();
    leaveEncashmentController.clear();
    vrsController.clear();
    taxPaidController.clear();

    // Reset all boolean values
    setState(() {
      isSeniorCitizen = false;
      isDisabled = false;
      hasFamilyPension = false;
      hasHouseLoan = false;
      showResults = false;
      showOnlyReport = false;

      // Reset calculation results
      grossIncome = 0;
      totalDeductions = 0;
      taxableIncome = 0;
      calculatedTax = 0;
      finalTax = 0;
      taxPaid = 0;
      refundOrPay = 0;
      agriculturalIncome = 0;
      totalIncomeForRateCalculation = 0;
    });
  }

  double parseAmount(String text) {
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  void calculateTax() {
    // Get agricultural income separately
    agriculturalIncome = parseAmount(agricultureController.text);

    // Calculate Gross Income (excluding agricultural income for tax calculation)
    grossIncome = parseAmount(salaryController.text) +
        parseAmount(businessController.text) +
        parseAmount(professionalController.text) +
        parseAmount(rentController.text) +
        // Agricultural income is excluded from taxable income
        parseAmount(savingsInterestController.text) +
        parseAmount(winningsController.text) +
        parseAmount(giftsController.text) +
        parseAmount(pfInterestController.text);

    // Calculate Deductions under New Regime 2025-26
    double standardDeduction = 0;
    if (parseAmount(salaryController.text) > 0) {
      standardDeduction = 75000; // Standard deduction for salaried
    }

    double employerNPS = parseAmount(employerNPSController.text);
    double agniVeer = parseAmount(agniVeerController.text);

    // Family Pension Deduction (1/3 of pension or ₹25,000 whichever is lower)
    double familyPensionDeduction = 0;
    if (hasFamilyPension) {
      double pension = parseAmount(familyPensionController.text);
      familyPensionDeduction = min(pension / 3, 25000);
    }

    // House Loan Interest (up to rental income)
    double houseInterestDeduction = 0;
    if (hasHouseLoan) {
      double interest = parseAmount(houseInterestController.text);
      double rental = parseAmount(rentController.text);
      houseInterestDeduction = min(interest, rental);
    }

    // Savings Bank Interest
    double savingsInterestDeduction = 0;
    double savingsInterest = parseAmount(savingsInterestController.text);
    if (isSeniorCitizen) {
      savingsInterestDeduction = min(savingsInterest, 50000); // 80TTB for senior citizens
    } else {
      savingsInterestDeduction = min(savingsInterest, 10000); // 80TTA for others
    }

    // Transport Allowance for disabled
    double transportDeduction = 0;
    if (isDisabled) {
      transportDeduction = min(parseAmount(transportAllowanceController.text), 3200 * 12);
    }

    // Other exemptions
    double gratuityExemption = parseAmount(gratuityController.text);
    double leaveEncashmentExemption = parseAmount(leaveEncashmentController.text);
    double vrsExemption = parseAmount(vrsController.text);

    totalDeductions = standardDeduction +
        employerNPS +
        agniVeer +
        familyPensionDeduction +
        houseInterestDeduction +
        savingsInterestDeduction +
        transportDeduction +
        gratuityExemption +
        leaveEncashmentExemption +
        vrsExemption;

    // Calculate Taxable Income (excluding agricultural income)
    taxableIncome = max(0, grossIncome - totalDeductions);

    // Calculate total income for rate determination (including agricultural income)
    totalIncomeForRateCalculation = taxableIncome + agriculturalIncome;

    // Calculate Tax using partial integration method
    calculatedTax = calculateTaxWithAgriculturalIncome(taxableIncome, agriculturalIncome);

    // Add 4% Health & Education Cess
    finalTax = calculatedTax * 1.04;

    // Calculate Refund or Additional Tax
    taxPaid = parseAmount(taxPaidController.text);
    refundOrPay = finalTax - taxPaid;

    setState(() {
      showResults = true;
      showOnlyReport = true;
    });
  }

  double calculateTaxWithAgriculturalIncome(double nonAgriIncome, double agriIncome) {
    if (agriIncome == 0) {
      // No agricultural income, calculate normally
      return calculateTaxFromSlabs(nonAgriIncome);
    }

    // Partial Integration Method
    // Step 1: Calculate tax on total income (including agricultural)
    double totalIncome = nonAgriIncome + agriIncome;
    double taxOnTotalIncome = calculateTaxFromSlabs(totalIncome);

    // Step 2: Calculate tax on agricultural income alone
    double taxOnAgriIncome = calculateTaxFromSlabs(agriIncome);

    // Step 3: Tax on non-agricultural income = Tax on total - Tax on agricultural
    double taxOnNonAgriIncome = taxOnTotalIncome - taxOnAgriIncome;

    return max(0, taxOnNonAgriIncome);
  }

  double calculateTaxFromSlabs(double income) {
    // New Regime Tax Slabs 2025-26 (AY 2026-27)
    double tax = 0;

    if (income <= 1200000) {
      tax = 0; // No tax up to ₹12 lakh
    } else if (income <= 1600000) {
      tax = (income - 1200000) * 0.15; // 15% for ₹12-16 lakh
    } else if (income <= 2000000) {
      tax = 60000 + (income - 1600000) * 0.20; // 20% for ₹16-20 lakh
    } else if (income <= 2400000) {
      tax = 140000 + (income - 2000000) * 0.25; // 25% for ₹20-24 lakh
    } else {
      tax = 240000 + (income - 2400000) * 0.30; // 30% above ₹24 lakh
    }

    return tax;
  }

  String getEffectiveTaxRate() {
    if (taxableIncome > 0) {
      double rate = (calculatedTax / taxableIncome) * 100;
      return rate.toStringAsFixed(2);
    }
    return "0.00";
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    bool isRequired = false,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          prefixText: prefix,
          helperText: helper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1993C4), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildCheckbox({required String label, required bool value, required Function(bool?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1993C4),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1993C4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tax Report',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Income Summary Section
              _buildSummarySection(
                title: 'Income Summary',
                children: [
                  _buildResultRow('Gross Annual Income (Non-Agricultural)', grossIncome, icon: '💵'),
                  if (agriculturalIncome > 0) ...[
                    _buildResultRow('Agricultural Income (Exempt)', agriculturalIncome,
                        isExempt: true, icon: '🌾'),
                    _buildResultRow('Total Income for Rate Calculation', totalIncomeForRateCalculation,
                        icon: '📈'),
                  ],
                ],
              ),

              // Deductions Section
              _buildSummarySection(
                title: 'Deductions & Tax Calculation',
                children: [
                  _buildResultRow('Total Deductions', totalDeductions, icon: '⬇️'),
                  _buildResultRow('Taxable Income', taxableIncome, icon: '💼'),
                  _buildResultRow('Tax Calculated', calculatedTax, icon: '🧮'),
                  _buildResultRow('Effective Tax Rate', double.parse(getEffectiveTaxRate()),
                      isPercentage: true, icon: '📊'),
                  _buildResultRow('Tax with Health & Education Cess (4%)', finalTax, icon: '🏥'),
                ],
              ),

              // Final Summary Section
              _buildSummarySection(
                title: 'Payment Summary',
                children: [
                  _buildResultRow('Tax Already Paid', taxPaid, icon: '✅'),
                  const Divider(thickness: 2, color: Color(0xFF1993C4)),
                  _buildResultRow(
                    refundOrPay < 0 ? 'Refund Due' : 'Additional Tax to Pay',
                    refundOrPay.abs(),
                    isHighlighted: true,
                    icon: refundOrPay < 0 ? '💰' : '💸',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: refundOrPay < 0 ? Colors.green[50] :
                  refundOrPay > 0 ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: refundOrPay < 0 ? Colors.green :
                    refundOrPay > 0 ? Colors.orange : Colors.blue,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      refundOrPay < 0 ? Icons.celebration :
                      refundOrPay > 0 ? Icons.payment : Icons.check_circle,
                      size: 40,
                      color: refundOrPay < 0 ? Colors.green[700] :
                      refundOrPay > 0 ? Colors.orange[700] : Colors.blue[700],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      refundOrPay < 0
                          ? 'Congratulations! \nYou are eligible for a refund of ₹${refundOrPay.abs().toStringAsFixed(0)}'
                          : refundOrPay > 0
                          ? 'Payment Required \nYou need to pay additional tax of ₹${refundOrPay.toStringAsFixed(0)}'
                          : 'All Set! \nYour tax is fully paid. No additional payment or refund required.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: refundOrPay < 0 ? Colors.green[800] :
                        refundOrPay > 0 ? Colors.orange[800] : Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Agricultural Income Impact
              if (agriculturalIncome > 0) ...[
                const SizedBox(height: 20),
                _buildInfoBox(
                  title: 'Agricultural Income Impact',
                  color: Colors.blue,
                  items: [
                    'Agricultural income of ₹${agriculturalIncome.toStringAsFixed(0)} is completely tax-exempt',
                    'However, it increases your tax rate to ${getEffectiveTaxRate()}% for other income',
                    'Tax is calculated using the partial integration method as per Income Tax Act',
                    'Higher agricultural income pushes you to higher tax brackets for non-agricultural income',
                  ],
                ),
              ],

              // Tax Optimization Tips
              if (taxableIncome > 0) ...[
                const SizedBox(height: 20),
                _buildOptimizationSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1993C4),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String title, required Color color, required List<String> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildOptimizationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                'Smart Tax Optimization Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...getTaxOptimizationTips(),
        ],
      ),
    );
  }

  List<Widget> getTaxOptimizationTips() {
    List<Map<String, dynamic>> tipsList = [];

    // Essential tips for everyone
    tipsList.add({
      'title': 'Maximize NPS Benefits',
      'description': 'Increase employer NPS contribution (Section 80CCD(2)) - it\'s fully tax-deductible with no upper limit!'
    });

    tipsList.add({
      'title': 'Claim All Exemptions',
      'description': 'Don\'t miss out on statutory exemptions for gratuity, leave encashment, and VRS payments.'
    });

    // Agricultural income specific tips
    if (agriculturalIncome > 0) {
      tipsList.add({
        'title': 'Time Your Agricultural Income',
        'description': 'Consider timing of agricultural income realization across financial years to manage your tax brackets effectively.'
      });

      tipsList.add({
        'title': 'Understand Rate Impact',
        'description': 'Your agricultural income of ₹${agriculturalIncome.toStringAsFixed(0)} is tax-free but increases your effective tax rate to ${getEffectiveTaxRate()}%.'
      });

      if (totalIncomeForRateCalculation > 2000000) {
        tipsList.add({
          'title': 'Consider Income Splitting',
          'description': 'Your total income pushes you to higher tax brackets. Consider legitimate income splitting strategies with family members.'
        });
      }
    }

    // Income bracket specific tips
    if (taxableIncome > 1200000) {
      tipsList.add({
        'title': 'Stay in Lower Brackets',
        'description': 'You\'re in the 15% tax bracket. Consider increasing deductible investments to optimize your tax liability.'
      });
    }

    // Property income tips
    if (parseAmount(rentController.text) > 0 && hasHouseLoan) {
      tipsList.add({
        'title': 'Rental Property Deduction',
        'description': 'House loan interest deduction is limited to the rental income from that specific property only.'
      });
    }

    // Age-specific tips
    if (isSeniorCitizen) {
      tipsList.add({
        'title': 'Senior Citizen Benefits',
        'description': 'As a senior citizen, you can claim up to ₹50,000 deduction for bank interest under Section 80TTB.'
      });
    } else {
      tipsList.add({
        'title': 'Bank Interest Deduction',
        'description': 'You can claim up to ₹10,000 deduction for savings bank interest under Section 80TTA.'
      });
    }

    // High income tips
    if (taxableIncome > 2400000) {
      tipsList.add({
        'title': 'Compare Tax Regimes',
        'description': 'Consider switching to Old Regime if you have significant investments in 80C, 80D, or other traditional deductions.'
      });

      tipsList.add({
        'title': 'Tax-Efficient Investments',
        'description': 'Explore ELSS mutual funds, PPF, and other tax-efficient investment options under the Old Regime.'
      });
    }

    return tipsList.map((tip) => _buildTaxTipCard(
      icon: tip['icon'],
      title: tip['title'],
      description: tip['description'],
    )).toList();
  }

  Widget _buildTaxTipCard({required String icon, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double amount, {
    bool isHighlighted = false,
    bool isExempt = false,
    bool isPercentage = false,
    String? icon
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isHighlighted ? 16 : 14,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                      color: isExempt ? Colors.green[700] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted ? const Color(0xFF1993C4).withOpacity(0.1) :
              isExempt ? Colors.green[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPercentage ? '${amount.toStringAsFixed(2)}%' : '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isHighlighted ? 16 : 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? const Color(0xFF1993C4) :
                isExempt ? Colors.green[700] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Personal Information
            _buildSectionCard(
              title: 'Personal Information',
              child: Column(
                children: [
                  _buildCheckbox(
                    label: 'Are you a Senior Citizen (60+ years)?',
                    value: isSeniorCitizen,
                    onChanged: (value) => setState(() => isSeniorCitizen = value!),
                  ),
                  _buildCheckbox(
                    label: 'Are you disabled?',
                    value: isDisabled,
                    onChanged: (value) => setState(() => isDisabled = value!),
                  ),
                ],
              ),
            ),

            // Income Information
            _buildSectionCard(
              title: 'Income Information',
              child: Column(
                children: [
                  _buildTextField(
                    controller: salaryController,
                    label: 'Salary/Pension Income',
                    prefix: '₹ ',
                    helper: 'Standard deduction of ₹75,000 applicable',
                  ),
                  _buildTextField(
                    controller: businessController,
                    label: 'Business Income',
                    prefix: '₹ ',
                  ),
                  _buildTextField(
                    controller: professionalController,
                    label: 'Professional Income',
                    prefix: '₹ ',
                  ),
                  _buildTextField(
                    controller: rentController,
                    label: 'Rental Income',
                    prefix: '₹ ',
                  ),
                  _buildTextField(
                    controller: agricultureController,
                    label: 'Agricultural Income',
                    prefix: '₹ ',
                    helper: 'Exempt from tax but affects tax rate calculation',
                  ),
                  _buildTextField(
                    controller: savingsInterestController,
                    label: 'Savings Bank Interest',
                    prefix: '₹ ',
                    helper: isSeniorCitizen ? 'Up to ₹50,000 exempt' : 'Up to ₹10,000 exempt',
                  ),
                  _buildTextField(
                    controller: winningsController,
                    label: 'Winnings (Lottery, etc.)',
                    prefix: '₹ ',
                  ),
                  _buildTextField(
                    controller: giftsController,
                    label: 'Gifts Received',
                    prefix: '₹ ',
                  ),
                  _buildTextField(
                    controller: pfInterestController,
                    label: 'PF Interest',
                    prefix: '₹ ',
                  ),
                ],
              ),
            ),

            // Deductions under New Regime
            _buildSectionCard(
              title: 'Deductions & Exemptions (New Regime)',
              child: Column(
                children: [
                  _buildTextField(
                    controller: employerNPSController,
                    label: 'Employer NPS Contribution',
                    prefix: '₹ ',
                    helper: 'Section 80CCD(2) - Fully deductible',
                  ),
                  _buildTextField(
                    controller: agniVeerController,
                    label: 'Agniveer Corpus Fund',
                    prefix: '₹ ',
                    helper: 'Section 80CCH(2)',
                  ),
                  _buildCheckbox(
                    label: 'Do you receive family pension?',
                    value: hasFamilyPension,
                    onChanged: (value) => setState(() => hasFamilyPension = value!),
                  ),
                  if (hasFamilyPension)
                    _buildTextField(
                      controller: familyPensionController,
                      label: 'Family Pension Amount',
                      prefix: '₹ ',
                      helper: '1/3 of pension or ₹25,000 (whichever is lower)',
                    ),
                  _buildCheckbox(
                    label: 'Do you have house loan for let-out property?',
                    value: hasHouseLoan,
                    onChanged: (value) => setState(() => hasHouseLoan = value!),
                  ),
                  if (hasHouseLoan)
                    _buildTextField(
                      controller: houseInterestController,
                      label: 'House Loan Interest',
                      prefix: '₹ ',
                      helper: 'Up to rental income from that property',
                    ),
                  if (isDisabled)
                    _buildTextField(
                      controller: transportAllowanceController,
                      label: 'Transport Allowance',
                      prefix: '₹ ',
                      helper: 'Up to ₹3,200 per month for disabled',
                    ),
                  _buildTextField(
                    controller: gratuityController,
                    label: 'Gratuity Received',
                    prefix: '₹ ',
                    helper: 'Statutory exemption applicable',
                  ),
                  _buildTextField(
                    controller: leaveEncashmentController,
                    label: 'Leave Encashment',
                    prefix: '₹ ',
                    helper: 'Statutory exemption applicable',
                  ),
                  _buildTextField(
                    controller: vrsController,
                    label: 'VRS/Voluntary Retirement',
                    prefix: '₹ ',
                    helper: 'Statutory exemption applicable',
                  ),
                ],
              ),
            ),

            // Tax Paid
            _buildSectionCard(
              title: 'Tax Already Paid',
              child: _buildTextField(
                controller: taxPaidController,
                label: 'Tax Paid (TDS + Advance Tax)',
                prefix: '₹ ',
                helper: 'Enter total tax already paid',
              ),
            ),

            // Calculate Button
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: calculateTax,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1993C4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Tax Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Results
            if (showResults) _buildResultCard(            ),
            const SizedBox(height: 16),
            // Back to Form Button
          ],
        ),
      ),
    );
  }
}