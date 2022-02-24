// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import {DataTablesModule } from 'angular-datatables';
import { SpiderRoutingModule } from './spider-routing.module';
import { SpiderComponent } from './spider.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';


@NgModule({
    imports: [CommonModule, SpiderRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule],
    declarations: [SpiderComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [SpiderComponent]
})
export class SpiderModule {}
