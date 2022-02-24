import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { MissingcompRoutingModule } from './missingcomp-routing.module';
import { MissingcompComponent } from './missingcomp.component';
import { PageHeaderModule } from '../../shared';

@NgModule({
    imports: [CommonModule, MissingcompRoutingModule, PageHeaderModule,DataTablesModule],
    declarations: [MissingcompComponent]
})
export class MissingcompModule {}
