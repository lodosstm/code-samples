package com.lodoss.presentation.round.preparation;

import com.lodoss.domain.interactor.step.GetListStepUseCase;
import com.lodoss.presentation.view_model.step.StepNumber;
import com.lodoss.presentation.view_model.step.StepsMapper;
import com.orhanobut.logger.Logger;

import javax.inject.Inject;

public class StepListPresenter extends StepListContract.Presenter {

    private GetListStepUseCase mGetListStepUseCase;
    private StepsMapper mStepsMapper;

    @Inject
    protected StepListPresenter(StepListContract.View view, StepListContract.Navigator navigator,
                                GetListStepUseCase getListStepUseCase, StepsMapper stepsMapper) {
        super(view, navigator);
        mGetListStepUseCase = getListStepUseCase;
        mStepsMapper = stepsMapper;
    }

    @Override
    public void setStep(String roundId, StepNumber stepNumber) {
        mGetListStepUseCase.execute(
                stepEntity -> mView.showStep(mStepsMapper.transform(stepEntity)),
                error -> Logger.e(error, error.getMessage()),
                mStepsMapper.toRequest(roundId, stepNumber));
    }

}
