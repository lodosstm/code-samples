package com.lodoss.presentation.round.preparation;

import com.lodoss.presentation.base.BaseView;
import com.lodoss.presentation.view_model.step.StepViewModel;

public interface StepListContract {

    interface View extends BaseView {

        void showStep(StepViewModel stepViewModel);

    }

    abstract class Presenter extends BaseView<View, Navigator> {

        protected Presenter(View view, Navigator navigator) {
            super(view, navigator);
        }

        public abstract void setStep(String roundId, StepNumber stepNumber);

    }

    interface Navigator {

        void openAddingListItems(String stepId);

    }

}
