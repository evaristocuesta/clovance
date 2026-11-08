import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Icon } from '../icon/icon';
import { ConfirmDialogOptions } from './confirm-dialog-options';
import { DIALOG_DATA, DialogRef } from '@angular/cdk/dialog';
import { IconName } from '../icon/icon-name';
import { Dialog } from '../dialog/dialog';

@Component({
  selector: 'app-confirm-dialog',
  imports: [CommonModule, Icon, Dialog],
  templateUrl: './confirm-dialog.html',
  styleUrl: './confirm-dialog.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmDialog {
  dialogRef = inject<DialogRef>(DialogRef);
  data = inject<ConfirmDialogOptions | undefined>(DIALOG_DATA);

  protected get confirmIcon(): IconName | null {
    return this.data?.confirmIcon ?? 'check';
  }

  cancel(): void {
    this.dialogRef.close(false);
  }

  accept(): void {
    this.dialogRef.close(true);
  }
}
