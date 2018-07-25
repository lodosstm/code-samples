package com.lodoss.data.entity.step;

import android.arch.persistence.room.Relation;

import com.lodoss.data.entity.person.PersonEntity;

import java.util.List;

public class PeopleStep extends BaseStep {

    @Relation(parentColumn = "id", entityColumn = "step_id")
    public List<PersonEntity> persons;

}
