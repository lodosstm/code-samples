package com.lodoss.proj.domain.interactors

import com.lodoss.proj.db.dao.UserDao
import com.lodoss.proj.db.entities.UserEntity
import com.lodoss.proj.db.transform
import com.lodoss.proj.domain.executors.PostExecutionThread
import com.lodoss.proj.domain.executors.ThreadExecutor
import com.lodoss.proj.network.VkRestApi
import io.reactivex.Single
import java.util.*
import javax.inject.Inject

class GetFriendsUseCase
@Inject protected constructor(
        threadExecutor: ThreadExecutor,
        postExecutionThread: PostExecutionThread,
        private val vkRestApi: VkRestApi,
        private val userDao: UserDao
) : SingleUseCase<List<UserEntity>, Int> (threadExecutor, postExecutionThread) {

    override fun buildUseCaseObservable(userId: Int?): Single<List<UserEntity>> =
            if (userId == null)
                Single.just(emptyList())
            else
                vkRestApi.getUser(userId, "photo_50")
                        .map { userDao.insert(transform(it.response[0])) }
                        .flatMap {  vkRestApi.getFriends(userId, "photo_50") }
                        .map { transform(it.response.items) }

}
