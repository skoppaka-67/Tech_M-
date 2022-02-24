// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import {DataTablesModule } from 'angular-datatables';
import { ControlFlowRoutingModule } from './controlflow-routing.module';
import { ControlFlowComponent } from './controlflow.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';


@NgModule({
    imports: [CommonModule, ControlFlowRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule],
    declarations: [ControlFlowComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [ControlFlowComponent]
})
export class ControlFlowModule {}
