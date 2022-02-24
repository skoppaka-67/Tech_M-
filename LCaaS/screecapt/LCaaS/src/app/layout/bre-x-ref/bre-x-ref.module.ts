// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

import { CommonModule } from '@angular/common';


import {DataTablesModule } from 'angular-datatables';

import { BreXRefRoutingModule } from './bre-x-ref-routing.module';
import { BreXRefComponent } from './bre-x-ref.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';

import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';



@NgModule({
    imports: [CommonModule, BreXRefRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule,
        NgbModule],
    declarations: [BreXRefComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [BreXRefComponent]
})
export class BreXRefModule {}
