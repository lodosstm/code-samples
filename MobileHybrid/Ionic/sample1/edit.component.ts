import { Component, OnInit, Input, OnDestroy } from '@angular/core';
import { ModalController } from '@ionic/angular';
import { IError, TEditFunc } from '@app/types';
import { ErrorConsts, ErrorService } from '@app/core/error';
import { Subscription } from 'rxjs';
import { SelectorService } from '@app/core/selector';

@Component({
  selector: 'modal-edit',
  templateUrl: './edit.component.html',
  styleUrls: ['./edit.component.scss']
})
export class EditComponent implements OnInit, OnDestroy {
  @Input('lot') lot: string;
  @Input('qty') qty: string;
  @Input('edit') edit: TEditFunc;

  public value: number;
  private error: IError;
  private subError: Subscription;

  constructor(private modal: ModalController, private error$: ErrorService, private selector$: SelectorService) {}

  ngOnInit() {
    this.value = parseInt(this.qty, 10);
    this.subError = this.selector$.selectError(this.initError, ErrorConsts.ERROR_STATUSES.EDIT_BATCH_QTY);
  }

  ngOnDestroy() {
    this.subError.unsubscribe();
  }

  public get isError(): boolean {
    return this.error.isError;
  }

  public get getMessage(): string {
    return this.error.message;
  }

  public editQty() {
    if (this.isPositiveNumber) {
      this.edit(this.value);
      this.modal.dismiss();
      this.error$.cleanError();
    } else {
      this.error$.fireEditBatchQtyError();
    }
  }

  public cancel(): void {
    this.modal.dismiss();
    this.error$.cleanError();
  }

  private initError = (error: IError): void => {
    this.error = error;
  };

  private get isPositiveNumber(): boolean {
    try {
      return this.value >= 0;
    } catch (err) {
      return false;
    }
  }
}
