package com.lodoss.data.local.converters;

import android.arch.persistence.room.TypeConverter;

import com.lodoss.data.entity.step.StepNumber;

public class StepNumberConverter {

    private StepNumberConverter() {}

    @TypeConverter
    public static StepNumber from(Integer value) {
        return StepNumber.parse(value);
    }

    @TypeConverter
    public static Integer to(StepNumber stepNumber) {
        return stepNumber.getValue();
    }

}
