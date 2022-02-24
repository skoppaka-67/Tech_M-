import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

import { MsgLogRoutingModule } from './msglog-routing.module';
import { MsgLogComponent } from './msglog.component';
import { PageHeaderModule } from '../../shared';
import { FormsModule } from '@angular/forms';
import { AngularDraggableModule } from 'angular2-draggable';
import { DataTablesModule } from 'angular-datatables';
import { ChartsModule as Ng2Charts } from 'ng2-charts';


@NgModule({
    imports: [CommonModule, MsgLogRoutingModule, PageHeaderModule, FormsModule, NgbModule, AngularDraggableModule, DataTablesModule, Ng2Charts ],
    declarations: [ MsgLogComponent ],
    bootstrap:    [ MsgLogComponent ]
})
export class MsgLogModule {}
