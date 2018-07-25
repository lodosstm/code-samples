import AppError from '../../../common/error-default';

export default class FavoriteListAlreadyExist extends AppError {
  public status: number = 400;
  public message: string = 'Favorite list already exist';

  constructor(info?: any) {
    super(__filename, info);
  }
}
