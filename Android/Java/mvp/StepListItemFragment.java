package com.lodoss.mobile_ui.round.preparation;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v7.widget.DividerItemDecoration;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.lodoss.R;
import com.lodoss.commons.SettingsManager;
import com.lodoss.presentation.round.preparation.BaseStepPresenter;
import com.lodoss.presentation.round.preparation.StepListContract;
import com.lodoss.presentation.view_model.comments.CommentListItemViewModel;
import com.lodoss.presentation.view_model.step.ListItem;
import com.lodoss.presentation.view_model.step.StepViewModel;

import java.util.List;

import javax.inject.Inject;

import butterknife.BindView;

public class StepListItemFragment extends BaseStepFragment implements StepListContract.View {

    @BindView(R.id.layout_step_root)
    protected ViewGroup mLayoutRoot;

    @BindView(R.id.text_title)
    protected TextView mTextTitle;

    @BindView(R.id.text_description)
    protected TextView mTextDescription;

    @BindView(R.id.layout_items)
    protected ViewGroup mLayoutListItems;

    @BindView(R.id.recycler_view_items)
    protected RecyclerView mRecyclerViewItems;

    @BindView(R.id.layout_comments)
    protected ViewGroup mLayoutComments;

    @BindView(R.id.recycler_view_comments)
    protected RecyclerView mRecyclerViewComments;

    @Inject
    protected StepListContract.Presenter mPresenter;

    @Inject
    protected SettingsManager mSettingsManager;

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, Bundle savedInstanceState) {
        View view = super.onCreateView(inflater, container, savedInstanceState);

        initRecyclerView(mRecyclerViewItems);
        initRecyclerView(mRecyclerViewComments);

        return view;
    }

    @Override
    protected BaseStepPresenter getPresenter() {
        return mPresenter;
    }

    @Override
    protected String getTitle() {
        return null;
    }

    @Override
    protected int getLayoutId() {
        return R.layout.fragment_list_item_step;
    }

    @Override
    public void showStep(StepViewModel stepViewModel) {
        mTextTitle.setText(getStepTitle(stepViewModel.getStepNumber().ordinal()));
        mTextDescription.setText(getStepDescription(stepViewModel.getStepNumber().ordinal()));
        setListItems(stepViewModel.getListItems());
        setComments(stepViewModel.getComments());
    }

    private void setListItems(List<ListItem> listItems) {
        if (listItems.size() > 0) {
            mLayoutListItems.setVisibility(View.VISIBLE);

            ListItemsAdapter adapter = new ListItemsAdapter(getActivity());
            adapter.setItems(listItems);
            mRecyclerViewItems.setAdapter(adapter);
        } else {
            mLayoutListItems.setVisibility(View.GONE);
        }
    }

    private void setComments(List<CommentListItemViewModel> comments) {
        if (comments.size() > 0) {
            mLayoutComments.setVisibility(View.VISIBLE);

            CommentsAdapter adapter = new CommentsAdapter(getActivity(), mSettingsManager.getLocale());
            adapter.setItems(comments);
            mRecyclerViewComments.setAdapter(adapter);
        } else {
            mLayoutComments.setVisibility(View.GONE);
        }
    }

    @Override
    public void setViewEnabled(boolean enabled) {
        mLayoutRoot.setEnabled(enabled);
    }

}
