import AppError from '../../../common/error-default';

export default class FavoriteListIsNotExist extends AppError {
  public status: number = 404;
  public message: string = 'Favorite list is not exist';

  constructor(info?: any) {
    super(__filename, info);
  }
}
