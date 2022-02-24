import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

import { TechSpecRoutingModule } from './techspec-routing.module';
import { TechSpecComponent } from './techspec.component';
import { PageHeaderModule } from '../../shared';
import { FormsModule } from '@angular/forms';
import { AngularDraggableModule } from 'angular2-draggable';
import { DataTablesModule } from 'angular-datatables';
import { PdfViewerModule } from 'ng2-pdf-viewer';
import { HttpModule } from '@angular/http';


@NgModule({
    imports: [ HttpModule, CommonModule, TechSpecRoutingModule, PageHeaderModule, FormsModule, NgbModule, AngularDraggableModule, DataTablesModule, PdfViewerModule ],    declarations: [ TechSpecComponent ],
    bootstrap:    [ TechSpecComponent ]
})
export class TechSpecModule {}
