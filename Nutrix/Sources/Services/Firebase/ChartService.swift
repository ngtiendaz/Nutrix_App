import Foundation
import FirebaseFirestore
import UIKit

extension FirebaseService {
    
    // MARK: - 1. THỐNG KÊ THEO TUẦN (Luôn đủ 7 cột từ T2 -> CN)
    func fetchWeeklyStatistics(
        userId: String,
        for date: Date,
        completion: @escaping (Result<StatisticsReport, Error>) -> Void
    ) {
        let calendar = Calendar.current
        var calendarWithMonday = calendar
        calendarWithMonday.firstWeekday = 2 // Đặt Thứ 2 là đầu tuần
        
        guard let mondayDate = calendarWithMonday.dateInterval(of: .weekOfYear, for: date)?.start else {
            completion(.failure(NSError(domain: "Nutrix", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không xác định được ngày đầu tuần"])))
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var weekKeys: [String] = []
        var weekDates: [Date] = []
        let weekdayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        
        // Sinh đủ cấu trúc thời gian 7 ngày trong tuần
        for i in 0..<7 {
            if let dayDate = calendarWithMonday.date(byAdding: .day, value: i, to: mondayDate) {
                let key = formatter.string(from: dayDate)
                weekKeys.append(key)
                weekDates.append(dayDate)
            }
        }
        
        guard let startKey = weekKeys.first, let endKey = weekKeys.last else { return }
        
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: DailySummary.self) } ?? []
                var points: [MetricPoint] = []
                
                // Vòng lặp map dữ liệu đồng bộ
                for (index, key) in weekKeys.enumerated() {
                    let label = weekdayLabels[index]
                    let currentDate = weekDates[index]
                    
                    if let daySummary = summaries.first(where: { $0.dateKey == key }) {
                        // Trường hợp CÓ dữ liệu ghi chép từ Firebase
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: daySummary.intakeCalories,
                            targetCalories: daySummary.targetCalories,
                            burnedCalories: daySummary.burnedCalories,
                            protein: daySummary.intakeProtein,
                            carbs: daySummary.intakeCarbs,
                            fat: daySummary.intakeFats,
                            hasPlan: daySummary.targetCalories > 0 // Có plan nếu target lớn hơn 0
                        ))
                    } else {
                        // Trường hợp KHÔNG CÓ dữ liệu lộ trình / Ngày tương lai trống
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: 0,
                            targetCalories: 0,
                            burnedCalories: 0,
                            protein: 0,
                            carbs: 0,
                            fat: 0,
                            hasPlan: false // Đánh dấu false để ẩn % và hiện badge chữ
                        ))
                    }
                }
                completion(.success(StatisticsReport(summaryPoints: points)))
            }
    }
    
    // MARK: - 2. THỐNG KÊ THEO THÁNG (Sinh đủ ngày trong tháng phục vụ phân trang)
    func fetchMonthlyStatistics(
        userId: String,
        month: Int,
        year: Int,
        completion: @escaping (Result<StatisticsReport, Error>) -> Void
    ) {
        let startKey = String(format: "%04d-%02d-01", year, month)
        let endKey = String(format: "%04d-%02d-31", year, month)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: DailySummary.self) } ?? []
                var points: [MetricPoint] = []
                let calendar = Calendar.current
                
                var components = DateComponents(year: year, month: month, day: 1)
                guard let startDate = calendar.date(from: components),
                      let range = calendar.range(of: .day, in: .month, for: startDate) else { return }
                
                for day in 1...range.count {
                    components.day = day
                    guard let currentDate = calendar.date(from: components) else { continue }
                    let currentKey = formatter.string(from: currentDate)
                    let label = String(format: "%02d", day)
                    
                    if let daySummary = summaries.first(where: { $0.dateKey == currentKey }) {
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: daySummary.intakeCalories,
                            targetCalories: daySummary.targetCalories,
                            burnedCalories: daySummary.burnedCalories,
                            protein: daySummary.intakeProtein,
                            carbs: daySummary.intakeCarbs,
                            fat: daySummary.intakeFats,
                            hasPlan: daySummary.targetCalories > 0
                        ))
                    } else {
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: 0,
                            targetCalories: 0,
                            burnedCalories: 0,
                            protein: 0,
                            carbs: 0,
                            fat: 0,
                            hasPlan: false
                        ))
                    }
                }
                completion(.success(StatisticsReport(summaryPoints: points.sorted { $0.label < $1.label })))
            }
    }
    
    // MARK: - 3. THỐNG KÊ THEO NĂM
    func fetchYearlyStatistics(
        userId: String,
        year: Int,
        completion: @escaping (Result<StatisticsReport, Error>) -> Void
    ) {
        let startKey = "\(year)-01-01"
        let endKey = "\(year)-12-31"
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: DailySummary.self) } ?? []
                var monthlyPoints: [MetricPoint] = []
                
                for month in 1...12 {
                    if year == currentYear && month > currentMonth { continue }
                    
                    let monthString = String(format: "%02d", month)
                    let targetPrefix = "\(year)-\(monthString)-"
                    let daysInMonth = summaries.filter { $0.dateKey.hasPrefix(targetPrefix) }
                    
                    if !daysInMonth.isEmpty {
                        let totalIntake = daysInMonth.reduce(0.0) { $0 + $1.intakeCalories }
                        let totalBurned = daysInMonth.reduce(0.0) { $0 + $1.burnedCalories }
                        let totalTarget = daysInMonth.reduce(0.0) { $0 + $1.targetCalories }
                        let avgTarget = totalTarget / Double(daysInMonth.count)
                        
                        monthlyPoints.append(MetricPoint(
                            label: "T\(month)",
                            date: nil,
                            intakeCalories: totalIntake,
                            targetCalories: avgTarget * Double(daysInMonth.count),
                            burnedCalories: totalBurned,
                            hasPlan: avgTarget > 0
                        ))
                    } else {
                        monthlyPoints.append(MetricPoint(
                            label: "T\(month)",
                            date: nil,
                            intakeCalories: 0,
                            targetCalories: 0,
                            burnedCalories: 0,
                            hasPlan: false
                        ))
                    }
                }
                completion(.success(StatisticsReport(summaryPoints: monthlyPoints)))
            }
    }
    private var reportCreationTimeString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm - dd/MM/yyyy"
            return formatter.string(from: Date())
        }
        
        // MARK: - 1. XUẤT FILE EXCEL / CSV CHUẨN ĐỊNH DẠNG HÀNG CỘT
        func generateCSV(from points: [MetricPoint], title: String, user: User?) -> URL? {
            func escapeCSV(_ field: String) -> String {
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\""
            }
            
            var csvString = ""
            
            // --- THÔNG TIN USER & PLAN (HEADER METADATA) ---
            csvString += "\"BÁO CÁO TIẾN ĐỘ DINH DƯỠNG NUTRIX\"\n"
            csvString += "\"Chu kỳ thống kê:\",\(escapeCSV(title))\n"
            csvString += "\"Họ và tên khách hàng:\",\(escapeCSV(user?.name ?? "Khách vãng lai"))\n"
            csvString += "\"Email đăng ký:\",\(escapeCSV(user?.email ?? "Chưa cập nhật"))\n"
            csvString += "\"Chiều cao hiện tại:\",\"\(Int(user?.height ?? 0)) cm\"\n"
            csvString += "\"Cân nặng hiện tại:\",\"\(Int(user?.weight ?? 0)) kg\"\n"
            csvString += "\"Thời gian xuất bản:\",\(escapeCSV(reportCreationTimeString))\n"
            csvString += "\n"
            
            // --- TIÊU ĐỀ BẢNG DỮ LIỆU ---
            csvString += "\"Thời gian\",\"Kcal Nạp Vào\",\"Kcal Mục Tiêu\",\"Tỷ lệ Hoàn Thành\",\"Kcal Tiêu Hao\",\"Chất Đạm (g)\",\"Tinh Bột (g)\",\"Chất Béo (g)\",\"Trạng thái Lộ trình\"\n"
            
            var totalIntake: Double = 0.0
            var totalBurned: Double = 0.0
            var totalTarget: Double = 0.0
            var totalProtein: Double = 0.0
            var totalCarbs: Double = 0.0
            var totalFat: Double = 0.0
            
            var planDaysCount: Double = 0.0
            var intakeDaysCount: Double = 0.0
            
            // --- DUYỆT QUA TỪNG NGÀY ĐỂ ĐỔ DỮ LIỆU ---
            for point in points {
                let label = point.label
                let intakeVal = point.intakeCalories
                let burnedVal = point.burnedCalories
                
                totalIntake += intakeVal
                totalBurned += burnedVal
                if intakeVal > 0 {
                    intakeDaysCount += 1
                }
                
                let intake = String(format: "%.0f", intakeVal)
                let burned = String(format: "%.0f", burnedVal)
                
                let target: String
                let protein: String
                let carbs: String
                let fat: String
                let completionRate: String
                let status: String
                
                if point.hasPlan && point.targetCalories > 0 {
                    planDaysCount += 1
                    totalTarget += point.targetCalories
                    totalProtein += point.protein
                    totalCarbs += point.carbs
                    totalFat += point.fat
                    
                    target = String(format: "%.0f", point.targetCalories)
                    protein = String(format: "%.1f", point.protein)
                    carbs = String(format: "%.1f", point.carbs)
                    fat = String(format: "%.1f", point.fat)
                    completionRate = String(format: "%.0f%%", point.completionRate)
                    status = point.status.rawValue
                } else {
                    target = ""
                    protein = ""
                    carbs = ""
                    fat = ""
                    completionRate = ""
                    status = "Không có lộ trình"
                }
                
                csvString += "\(escapeCSV(label)),\(intake),\(target),\(burned),\(protein),\(carbs),\(fat),\(escapeCSV(completionRate)),\(escapeCSV(status))\n"
            }
            
            // --- HÀNG TỔNG CỘNG VÀ TRUNG BÌNH ---
            csvString += "\n"
            
            let avgIntake = intakeDaysCount > 0 ? totalIntake / intakeDaysCount : 0.0
            let avgBurned = intakeDaysCount > 0 ? totalBurned / intakeDaysCount : 0.0
            let avgTarget = planDaysCount > 0 ? totalTarget / planDaysCount : 0.0
            let avgProtein = planDaysCount > 0 ? totalProtein / planDaysCount : 0.0
            let avgCarbs = planDaysCount > 0 ? totalCarbs / planDaysCount : 0.0
            let avgFat = planDaysCount > 0 ? totalFat / planDaysCount : 0.0
            let avgCompletionRate = planDaysCount > 0 ? (totalIntake / totalTarget) * 100 : 0.0
            
            // Hàng TỔNG CỘNG
            let totalTargetStr = planDaysCount > 0 ? String(format: "%.0f", totalTarget) : ""
            let totalProteinStr = planDaysCount > 0 ? String(format: "%.1f", totalProtein) : ""
            let totalCarbsStr = planDaysCount > 0 ? String(format: "%.1f", totalCarbs) : ""
            let totalFatStr = planDaysCount > 0 ? String(format: "%.1f", totalFat) : ""
            
            csvString += "\"TỔNG CỘNG\",\(String(format: "%.0f", totalIntake)),\(totalTargetStr),\"\",\(String(format: "%.0f", totalBurned)),\(totalProteinStr),\(totalCarbsStr),\(totalFatStr),\"\"\n"
            
            // Hàng TRUNG BÌNH/NGÀY
            let avgTargetStr = planDaysCount > 0 ? String(format: "%.0f", avgTarget) : ""
            let avgProteinStr = planDaysCount > 0 ? String(format: "%.1f", avgProtein) : ""
            let avgCarbsStr = planDaysCount > 0 ? String(format: "%.1f", avgCarbs) : ""
            let avgFatStr = planDaysCount > 0 ? String(format: "%.1f", avgFat) : ""
            let avgCompletionStr = planDaysCount > 0 ? String(format: "%.0f%%", avgCompletionRate) : ""
            
            csvString += "\"TRUNG BÌNH/NGÀY\",\(String(format: "%.0f", avgIntake)),\(avgTargetStr),\(escapeCSV(avgCompletionStr)),\(String(format: "%.0f", avgBurned)),\(avgProteinStr),\(avgCarbsStr),\(avgFatStr),\"\"\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd_MM_yy"
            let dateStr = dateFormatter.string(from: Date())
            let fileName = "Nutrix_\(dateStr)_report.csv"
            let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                let utf8WithBOM = NSMutableData()
                let bom = [UInt8]([0xEF, 0xBB, 0xBF]) // Thêm BOM chống lỗi font tiếng Việt trên Excel Windows
                utf8WithBOM.append(bom, length: 3)
                
                if let data = csvString.data(using: .utf8) {
                    utf8WithBOM.append(data)
                    try utf8WithBOM.write(to: path, options: .atomic)
                    return path
                }
            } catch {
                print("Lỗi ghi file CSV: \(error)")
            }
            return nil
        }
        
        // MARK: - 2. XUẤT FILE PDF CHUYÊN NGHIỆP (Bố cục tạp chí, màu chữ đen rõ nét)
        func generatePDF(from points: [MetricPoint], title: String, user: User?) -> URL? {
            let pdfMetaData = ["Author": "Nutrix App", "Title": "Báo cáo tiến độ - Nutrix"]
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = pdfMetaData
            
            let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // Khổ giấy A4 tiêu chuẩn
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd_MM_yy"
            let dateStr = dateFormatter.string(from: Date())
            let fileName = "Nutrix_\(dateStr)_report.pdf"
            let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try renderer.writePDF(to: path) { context in
                    context.beginPage()
                    
                    // --- THIẾT LẬP GRAPHICS & CẤU HÌNH COLOR ---
                    let primaryColor = UIColor(red: 74/255, green: 124/255, blue: 89/255, alpha: 1.0) // Màu xanh chủ đạo Nutrix
                    let blackColor = UIColor.black
                    let grayColor = UIColor.darkGray
                    
                    // 1. VẼ TIÊU ĐỀ CHÍNH
                    let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: primaryColor]
                    "NUTRIX - BÁO CÁO TIẾN ĐỘ DINH DƯỠNG".draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttr)
                    
                    let subAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: grayColor]
                    "Giai đoạn: \(title)".draw(at: CGPoint(x: 40, y: 68), withAttributes: subAttr)
                    
                    // FIX LỖI 1: Loại bỏ thuộc tính lai tạp .gradient không tồn tại trên UIColor
                    context.cgContext.setStrokeColor(primaryColor.cgColor)
                    context.cgContext.setLineWidth(2)
                    context.cgContext.move(to: CGPoint(x: 40, y: 90))
                    context.cgContext.addLine(to: CGPoint(x: 555, y: 90))
                    context.cgContext.strokePath()
                    
                    // 2. VẼ KHỐI HỒ SƠ NGƯỜI DÙNG & LỘ TRÌNH (USER PROFILE CARD)
                    let sectionTitleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: primaryColor]
                    "1. THÔNG TIN KHÁCH HÀNG & LỘ TRÌNH".draw(at: CGPoint(x: 40, y: 105), withAttributes: sectionTitleAttr)
                    
                    let boldLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: blackColor]
                    let normalValueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: blackColor]
                    
                    // Cột trái: Thông tin cá nhân
                    "Người dùng:".draw(at: CGPoint(x: 50, y: 132), withAttributes: boldLabelAttr)
                    "\(user?.name ?? "Không có dữ liệu")".draw(at: CGPoint(x: 140, y: 132), withAttributes: normalValueAttr)
                    
                    "Email:".draw(at: CGPoint(x: 50, y: 152), withAttributes: boldLabelAttr)
                    "\(user?.email ?? "Chưa liên kết")".draw(at: CGPoint(x: 140, y: 152), withAttributes: normalValueAttr)
                    
                    "Chỉ số hiện tại:".draw(at: CGPoint(x: 50, y: 172), withAttributes: boldLabelAttr)
                    let userHeight = user?.height ?? 0
                    let userWeight = user?.weight ?? 0
                    let heightText = userHeight > 0 ? "\(Int(userHeight)) cm" : "-- cm"
                    let weightText = userWeight > 0 ? "\(Int(userWeight)) kg" : "-- kg"
                    "\(heightText)  |  \(weightText)".draw(at: CGPoint(x: 140, y: 172), withAttributes: normalValueAttr)
                    let activePlanPoint = points.first(where: { $0.hasPlan && $0.targetCalories > 0 })
                    let currentPlanText = activePlanPoint != nil ? "\(Int(activePlanPoint!.targetCalories)) Kcal/ngày" : "Chưa có lộ trình"
                    
                    "Lộ trình mục tiêu:".draw(at: CGPoint(x: 320, y: 132), withAttributes: boldLabelAttr)
                    "\(currentPlanText)".draw(at: CGPoint(x: 435, y: 132), withAttributes: normalValueAttr)
                    
                    "Trạng thái:".draw(at: CGPoint(x: 320, y: 152), withAttributes: boldLabelAttr)
                    "\(activePlanPoint != nil ? "Đang áp dụng" : "Không có")".draw(at: CGPoint(x: 435, y: 152), withAttributes: normalValueAttr)
                    
                    "Thời gian tạo:".draw(at: CGPoint(x: 320, y: 172), withAttributes: boldLabelAttr)
                    "\(reportCreationTimeString)".draw(at: CGPoint(x: 435, y: 172), withAttributes: normalValueAttr)
                    
                    // Khung viền bao bọc thông tin user
                    context.cgContext.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.4).cgColor)
                    context.cgContext.setLineWidth(1)
                    context.cgContext.addRect(CGRect(x: 40, y: 122, width: 515, height: 66))
                    context.cgContext.strokePath()
                    
                    // 3. VẼ BẢNG SỐ LIỆU CHI TIẾT TIẾN ĐỘ CHU KỲ
                    var currentY: CGFloat = 210
                    "2. CHI TIẾT BIẾN ĐỘNG DINH DƯỠNG".draw(at: CGPoint(x: 40, y: currentY), withAttributes: sectionTitleAttr)
                    
                    currentY += 24
                    
                    let tableHeaderAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: blackColor]
                    let tableCellAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: blackColor]
                    
                    let headers = ["Thời gian", "Nạp vào", "Mục tiêu", "Tiêu hao", "Protein", "Carbs", "Fat"]
                    let widths: [CGFloat] = [70, 75, 75, 75, 55, 55, 55]
                    
                    var currentX: CGFloat = 40
                    for (idx, header) in headers.enumerated() {
                        header.draw(at: CGPoint(x: currentX, y: currentY), withAttributes: tableHeaderAttr)
                        currentX += widths[idx]
                    }
                    
                    // Đường thẳng mảnh ngăn cách hàng Header của bảng
                    context.cgContext.setStrokeColor(blackColor.cgColor)
                    context.cgContext.setLineWidth(1.2)
                    context.cgContext.move(to: CGPoint(x: 40, y: currentY + 16))
                    context.cgContext.addLine(to: CGPoint(x: 555, y: currentY + 16))
                    context.cgContext.strokePath()
                    
                    currentY += 26
                    
                    for point in points {
                        if currentY > 800 {
                            context.beginPage()
                            currentY = 40
                        }
                        
                        let targetStr = point.hasPlan ? String(format: "%.0f Kcal", point.targetCalories) : "--"
                        let proStr = point.hasPlan ? String(format: "%.1fg", point.protein) : "--"
                        let carbStr = point.hasPlan ? String(format: "%.1fg", point.carbs) : "--"
                        let fatStr = point.hasPlan ? String(format: "%.1fg", point.fat) : "--"
                        
                        let rowData = [
                            point.label,
                            String(format: "%.0f Kcal", point.intakeCalories),
                            targetStr,
                            String(format: "%.0f Kcal", point.burnedCalories),
                            proStr,
                            carbStr,
                            fatStr
                        ]
                        
                        var xPos: CGFloat = 40
                        for (idx, text) in rowData.enumerated() {
                            text.draw(at: CGPoint(x: xPos, y: currentY), withAttributes: tableCellAttr)
                            xPos += widths[idx]
                        }
                        currentY += 22
                    }
                }
                return path
            } catch {
                // FIX LỖI 2: Đổi từ biến cục bộ ảo 'context' thành hằng số bắt lỗi hệ thống 'error'
                print("Lỗi render PDF: \(error)")
                return nil
            }
        }
}
