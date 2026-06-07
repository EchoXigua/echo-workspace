package com.leanmate.ai.client;

import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportResult;

public interface DailyReportClient {

    DailyReportResult generateDailyReport(DailyReportInput input);
}
