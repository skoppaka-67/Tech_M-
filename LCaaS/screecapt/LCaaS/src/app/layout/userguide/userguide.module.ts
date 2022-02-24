import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

import { UserGuideRoutingModule } from './userguide-routing.module';
import { UserGuideComponent } from './userguide.component';
import { PageHeaderModule } from '../../shared';
import { FormsModule } from '@angular/forms';
import { AngularDraggableModule } from 'angular2-draggable';
import { DataTablesModule } from 'angular-datatables';
import { PdfViewerModule } from 'ng2-pdf-viewer';


@NgModule({
    imports: [ CommonModule, UserGuideRoutingModule, PageHeaderModule, FormsModule, NgbModule, AngularDraggableModule, DataTablesModule, PdfViewerModule ],    declarations: [ UserGuideComponent ],
    bootstrap:    [ UserGuideComponent ]
})
export class UserGuideModule {}
