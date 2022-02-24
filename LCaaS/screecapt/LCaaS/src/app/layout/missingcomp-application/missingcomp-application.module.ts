import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { MissingcompAppRoutingModule } from './missingcomp-application-routing.module';
import { MissingcompAppComponent } from './missingcomp-application.component';
import { PageHeaderModule } from '../../shared';

@NgModule({
    imports: [CommonModule, MissingcompAppRoutingModule, PageHeaderModule,DataTablesModule],
    declarations: [MissingcompAppComponent]
})
export class MissingcompAppModule {}
