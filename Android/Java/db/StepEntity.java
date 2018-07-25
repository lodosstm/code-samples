package com.lodoss.data.entity.step;

import android.arch.persistence.room.ColumnInfo;
import android.arch.persistence.room.Entity;
import android.arch.persistence.room.ForeignKey;
import android.arch.persistence.room.Ignore;
import android.arch.persistence.room.PrimaryKey;
import android.arch.persistence.room.TypeConverters;
import android.support.annotation.NonNull;

import com.lodoss.data.entity.SyncEntity;
import com.lodoss.data.entity.round.RoundEntity;
import com.lodoss.data.local.converters.DateConverter;
import com.lodoss.data.local.converters.StepNumberConverter;

import java.util.Date;

@Entity(tableName = StepEntity.TABLE_NAME,
        foreignKeys = @ForeignKey(entity = RoundEntity.class,
            parentColumns = "id",
            childColumns = "round_id"))
public class StepEntity extends SyncEntity {

    @Ignore
    public final static String TABLE_NAME = "steps";

    @PrimaryKey
    @ColumnInfo(name = "id", index = true)
    @NonNull
    public String id;

    @ColumnInfo(name = "step_number")
    @TypeConverters(StepNumberConverter.class)
    public StepNumber stepNumber;

    @ColumnInfo(name = "round_id", index = true)
    public String roundId;

    @ColumnInfo(name = "user_id")
    public long userId;

    @ColumnInfo(name = "is_decison_maker_known")
    public boolean isDecisonMakerKnown;

    @ColumnInfo(name = "is_discussed")
    public boolean isDiscussed;

    @ColumnInfo(name = "concessions_state")
    public int concessionsState;

    @ColumnInfo(name = "negotiations_context")
    public int negotiationsContext;

    @ColumnInfo(name = "is_deleted")
    public boolean isDeleted;

}
