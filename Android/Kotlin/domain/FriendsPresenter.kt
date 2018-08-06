package com.lodoss.proj.presentation.friends

import com.lodoss.proj.db.entities.UserEntity
import com.lodoss.proj.domain.interactors.GetFriendsUseCase
import javax.inject.Inject

class FriendsPresenter @Inject protected constructor(
        view: FriendsContract.View,
        navigator: FriendsContract.Navigator,
        private val getFriendsUseCase: GetFriendsUseCase) : FriendsContract.Presenter(view, navigator) {

    private var currentUserId = 0

    override fun load(id: Int) {
        currentUserId = id
        getFriendsUseCase.execute(
                { view.showFriendList(it) },
                currentUserId
        )
    }

    override fun friendSelected(friend: UserEntity) =
            navigator.goToUserFriendDetails(currentUserId, friend.id)

    override fun dispose() = getFriendsUseCase.dispose()
}