import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { MasterinvAppRoutingModule } from './masterinv-application-routing.module';
import { MasterinvAppComponent } from './masterinv-application.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, MasterinvAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [MasterinvAppComponent],
    providers: [ExcelService]
})
export class MasterinvAppModule {}
