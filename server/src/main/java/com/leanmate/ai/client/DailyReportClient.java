package com.leanmate.ai.client;

import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportResult;
import java.util.UUID;

public interface DailyReportClient {

    DailyReportResult generateDailyReport(DailyReportInput input);

    default DailyReportResult generateDailyReport(DailyReportInput input, UUID reportId) {
        return generateDailyReport(input);
    }
}
