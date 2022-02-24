// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import {DataTablesModule } from 'angular-datatables';
import { BatchFlowRoutingModule } from './batchflow-routing.module';
import { BatchFlowComponent } from './batchflow.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';


@NgModule({
    imports: [CommonModule, BatchFlowRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule],
    declarations: [BatchFlowComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [BatchFlowComponent]
})
export class BatchFlowModule {}
