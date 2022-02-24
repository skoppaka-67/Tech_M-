import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';
import { TreeViewComponent, TreeViewModule } from '@syncfusion/ej2-angular-navigations';
import { BsComponentExtRoutingModule } from './programprocessflow-external-routing.module';
import { BsComponentExtComponent } from './programprocessflow-external.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { PageHeaderModule } from './../../shared';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { AngularDraggableModule } from 'angular2-draggable';

import {
    AlertComponent,
    ButtonsComponent,
    ModalComponent,
    CollapseComponent,
    DatePickerComponent,
    DropdownComponent,
    PaginationComponent,
    PopOverComponent,
    ProgressbarComponent,
    TabsComponent,
    RatingComponent,
    TooltipComponent,
    TimepickerComponent
} from './components';


@NgModule({
    imports: [
        CommonModule,
        BsComponentExtRoutingModule,
        FormsModule,
        ReactiveFormsModule,
        NgbModule,
        PageHeaderModule,
        TreeViewModule,
        DataTablesModule,
        NgxGraphModule,
        NgxChartsModule,
        AngularDraggableModule

    ],
    declarations: [
        BsComponentExtComponent,
        ButtonsComponent,
        AlertComponent,
        ModalComponent,
        CollapseComponent,
        DatePickerComponent,
        DropdownComponent,
        PaginationComponent,
        PopOverComponent,
        ProgressbarComponent,
        TabsComponent,
        RatingComponent,
        TooltipComponent,
        TimepickerComponent
    ],
    bootstrap:    [ BsComponentExtComponent ]
})
export class BsComponentExtModule {}
