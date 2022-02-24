import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CICSXrefAppRoutingModule } from './cicsxref-application-routing.module';
import { CICSXrefAppComponent } from './cicsxref-application.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, CICSXrefAppRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [CICSXrefAppComponent]
})
export class CICSXrefAppModule {}
