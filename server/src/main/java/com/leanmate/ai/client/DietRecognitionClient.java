package com.leanmate.ai.client;

import com.leanmate.ai.dto.DietPhotoRecognitionInput;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;

public interface DietRecognitionClient {

    DietRecognitionResult recognizePhoto(DietPhotoRecognitionInput input);

    DietRecognitionResult recognizeText(DietTextRecognitionInput input);
}
