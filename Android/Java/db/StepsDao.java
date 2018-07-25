package com.lodoss.data.local.dao;

import android.arch.persistence.room.Dao;
import android.arch.persistence.room.Query;
import android.arch.persistence.room.Transaction;

import com.lodoss.data.entity.step.PeopleStep;
import com.lodoss.data.entity.step.StepEntity;

import java.util.List;

import io.reactivex.Single;

@Dao
public interface StepsDao extends BaseDao<StepEntity> {

    @Query("SELECT * FROM steps WHERE " +
            "is_new_item = 1")
    Single<List<StepEntity>> getNewSteps();

    @Query("SELECT * FROM steps WHERE " +
            "is_new_item = 0 AND sync_count > 0")
    Single<List<StepEntity>> getModifiedSteps();

    @Transaction
    @Query("SELECT * FROM steps WHERE " +
            "round_id = :roundId AND " +
            "step_number = :stepNumber")
    Single<PeopleStep> getPeopleStepByRound(String roundId, int stepNumber);

}
