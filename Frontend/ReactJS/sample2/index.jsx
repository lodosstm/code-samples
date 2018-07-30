import React, { Component } from 'react';
import { Field, reduxForm } from 'redux-form';
import createValidation, {
    REQUIRED,
    PHONE,
    ADDRESS,
    WEBSITE,
    EMAIL,
    STRING_MAX_LENGTH,
} from 'utils/validation';
import { isBusinessUserRejected } from 'models/user';
import {
    BUSINESS_NAME_MAX_LENGTH,
    CONTACT_NAME_MAX_LENGTH,
    CONTACT_POSITION_MAX_LENGTH,
    EMAIL_MAX_LENGTH,
    SITE_MAX_LENGTH,
} from 'config/validation';
import { normalizePhone } from 'models/phone';
import ChangeEmail from '../common/ChangeEmail';
import FormField from '../common/FormField';
import PhoneInput from '../common/PhoneInput';
import SaveButton from '../common/SaveButton';
import MessagePopup from '../../common/messages/MessagePopup';
import Address from '../../common/Address';
import Avatar from '../common/Avatar';
import LinkedSocial from '../common/LinkedSocial';
class MyInfo extends Component {
    constructor(props) {
        super(props);
        this.state = {
            isChangeEmailPopupOpen: false,
        };
        this.openChangeEmail = this.openChangeEmail.bind(this);
        this.closeChangeEmail = this.closeChangeEmail.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
    }
    onSubmit(value) {
        const {
            onSave,
            initialValues,
        } = this.props;
        onSave(value, initialValues);
    }
    openChangeEmail() {
        this.setState({
            isChangeEmailPopupOpen: true,
        });
    }
    closeChangeEmail() {
        this.setState({
            isChangeEmailPopupOpen: false,
        });
    }
    render() {
        const {
            handleSubmit,
            showSpinner,
            initialValues,
            submitFailed,
            valid,
            pristine,
            showSuccessfulMessage,
            clearRequestMessages,
            instagramUsername,
            userRole,
            accountStatus,
        } = this.props;
        const isRejected = isBusinessUserRejected(userRole, accountStatus);
        return (
            <form action="#" onSubmit={handleSubmit(this.onSubmit)} className="user-settings__content user-settings__content--medium">
                <div className="user-settings__main-settings">
                    <div className="left-column">
                        <h3 className="fields-mobile-title">
                            Profile Photo
                        </h3>
                        <Avatar
                            showSpinner={showSpinner}
                            url={initialValues.avatarUrl}
                            disabled={isRejected}
                        />
                    </div>
                    <div className="right-column">
                        <h3 className="fields-mobile-title">
                            Login Information
                        </h3>
                        <div className="field">
                            <div className="field__block">
                                <div className="user-settings__row">
                                    <span className="field__text">Account Email*</span>
                                    <button onClick={this.openChangeEmail} className="user-settings__edit-account-email-button">edit</button>
                                </div>
                                <Field component="input" disabled name="email" placeholder="Login Email" className="field__input" type="text" />
                            </div>
                        </div>
                    </div>
                </div>
                <div className="user-settings__splitter" />
                <h3 className="fields-mobile-title">
                    My Details
                </h3>
                <FormField name="contactName" disabled={isRejected} placeholder="Full Name" label="Contact Name*" type="text" maxLength={CONTACT_NAME_MAX_LENGTH} />
                <FormField name="contactPosition" disabled={isRejected} placeholder="Position in Business" label="Contact Position" type="text" />
                <div className="field">
                    <span className="field__text left-column">Contact Number*</span>
                    <Field
                        className="right-column"
                        component={PhoneInput}
                        name="contactPhone"
                        placeholder="Mobile"
                        type="text"
                        normalize={normalizePhone}
                        disabled={isRejected}
                    />
                </div>
                <div className="user-settings__splitter" />
                <FormField name="businessName" disabled={isRejected} placeholder="Business Name" label="Business Name*" type="text" maxLength={BUSINESS_NAME_MAX_LENGTH} />
                <div className="field">
                    <span className="field__text left-column">Business Address*</span>
                    <Field component={Address} disabled={isRejected} placeholder="Start typing..." showHint withTooltip name="address" />
                </div>
                <FormField name="businessEmail" disabled={isRejected} placeholder="Email" label="Business Email" type="text" maxLength={EMAIL_MAX_LENGTH} />
                <FormField name="siteUrl" disabled={isRejected} placeholder="Website" label="Business Website" type="text" maxLength={SITE_MAX_LENGTH} />
                <div className="field">
                    <span className="field__text left-column">Business Phone</span>
                    <Field
                        className="right-column"
                        component={PhoneInput}
                        name="businessPhone"
                        placeholder="Phone Number"
                        type="text"
                        normalize={normalizePhone}
                        disabled={isRejected}
                    />
                </div>
                <div className="user-settings__splitter" />
                <LinkedSocial instagramUsername={instagramUsername} disabled={isRejected} />
                <div className="user-settings__splitter" />
                <div className="user-settings__footer">
                    <SaveButton
                        type="submit"
                        submitFailed={submitFailed}
                        valid={valid}
                        pristine={pristine}
                        isRejected={isRejected}
                    />
                </div>
                <ChangeEmail onClose={this.closeChangeEmail} open={this.state.isChangeEmailPopupOpen} />
                <MessagePopup onClose={clearRequestMessages} title="Change Email" message="Please check your email. We&apos;ve sent you a link to change your account email." open={showSuccessfulMessage} />
            </form>
        );
    }
}
const MyInfoForm = reduxForm({
    form: 'MyInfo',
    validate: createValidation({
        contactName: [
            REQUIRED,
            ({ contactName }) =>
                STRING_MAX_LENGTH({ value: contactName, maxLength: CONTACT_NAME_MAX_LENGTH }),
        ],
        contactPosition: [
            ({ contactPosition }) =>
                STRING_MAX_LENGTH({ value: contactPosition, maxLength: CONTACT_POSITION_MAX_LENGTH }),
        ],
        contactPhone: [
            REQUIRED, PHONE,
        ],
        businessName: [
            REQUIRED,
            ({ businessName }) =>
                STRING_MAX_LENGTH({ value: businessName, maxLength: BUSINESS_NAME_MAX_LENGTH }),
        ],
        address: [
            REQUIRED, ADDRESS,
        ],
        businessEmail: [
            EMAIL,
            ({ businessEmail }) =>
                STRING_MAX_LENGTH({ value: businessEmail, maxLength: EMAIL_MAX_LENGTH }),
        ],
        siteUrl: [
            WEBSITE,
            ({ siteUrl }) =>
                STRING_MAX_LENGTH({ value: siteUrl, maxLength: SITE_MAX_LENGTH }),
        ],
        businessPhone: [
            PHONE,
        ],
    }),
    enableReinitialize: true,
    keepDirtyOnReinitialize: true,
})(MyInfo);

export default MyInfoForm;