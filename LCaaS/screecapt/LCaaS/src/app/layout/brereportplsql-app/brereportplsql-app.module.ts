// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

import { CommonModule } from '@angular/common';


import {DataTablesModule } from 'angular-datatables';

import { BreReportPlSqlAppRoutingModule } from './brereportplsql-app-routing.module';
import { BreReportPlSqlAppComponent } from './brereportplsql-app.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';

import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';



@NgModule({
    imports: [CommonModule, BreReportPlSqlAppRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule,
        NgbModule],
    declarations: [BreReportPlSqlAppComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [BreReportPlSqlAppComponent]
})
export class BreReportPlSqlAppModule {}
