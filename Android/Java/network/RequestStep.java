package com.lodoss.data.remote.models.step;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class RequestStep {

    @SerializedName("id")
    @Expose
    public String id;

    @SerializedName("round_id")
    @Expose
    public String roundId;

    @SerializedName("step_number")
    @Expose
    public int stepNumber;

    @SerializedName("date_modified")
    @Expose
    public String dateModified;

    @SerializedName("date_created")
    @Expose
    public String dateCreated;

    @SerializedName("is_deleted")
    @Expose
    public boolean isDeleted;

    @SerializedName("is_discussed")
    @Expose
    public boolean isDiscussed;
    
}
