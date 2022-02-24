import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CicsScreenAppRoutingModule } from './cicsscreenreport-application-routing.module';
import { CicsScreenAppComponent } from './cicsscreenreport-application.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, CicsScreenAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [CicsScreenAppComponent],
    providers: [ExcelService]
})
export class CicsScreenAppModule {}
