import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

import { SankeyRoutingModule } from './sankey-routing.module';
import { SankeyComponent } from './sankey.component';
import { PageHeaderModule } from '../../shared';
import { FormsModule } from '@angular/forms';
import { AngularDraggableModule } from 'angular2-draggable';
import { DataTablesModule } from 'angular-datatables';
import { ChartsModule as Ng2Charts } from 'ng2-charts';
import { GoogleChartsModule } from 'angular-google-charts';


@NgModule({
    imports: [CommonModule, SankeyRoutingModule, PageHeaderModule, FormsModule, NgbModule, AngularDraggableModule, DataTablesModule, Ng2Charts, GoogleChartsModule ],
    declarations: [SankeyComponent],
    bootstrap:    [ SankeyComponent ]
})
export class SankeyModule {}
