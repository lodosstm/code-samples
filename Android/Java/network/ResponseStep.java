package com.lodoss.data.remote.models.step;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class ResponseStep {

    @SerializedName("id")
    @Expose
    public String id;
    
    @SerializedName("step_number")
    @Expose
    public int stepNumber;
    
    @SerializedName("round_id")
    @Expose
    public String roundId;
    
    @SerializedName("user_id")
    @Expose
    public long userId;
    
    @SerializedName("is_decison_maker_known")
    @Expose
    public boolean isDecisonMakerKnown;
    
    @SerializedName("is_discussed")
    @Expose
    public boolean isDiscussed;
    
    @SerializedName("date_created")
    @Expose
    public String dateCreated;
    
    @SerializedName("date_modified")
    @Expose
    public String dateModified;
    
    @SerializedName("is_deleted")
    @Expose
    public boolean isDeleted;

}
