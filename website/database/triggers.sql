
/* Verificar numero de bilhetes em stock quando se comprar bilhete*/

CREATE OR REPLACE FUNCTION buy_ticket() RETURNS TRIGGER AS
$BODY$
DECLARE
	num_total_tickets integer;
	num_sold_tickets integer;
BEGIN
	IF tg_op = 'INSERT' THEN
		SELECT type_ticket.num_tickets INTO num_total_tickets
		FROM Type_of_Ticket type_ticket
		WHERE new.type_of_ticket_id = type_ticket.type_of_ticket_id;

		SELECT count(*) INTO num_sold_tickets
		FROM Ticket t
		WHERE t.type_of_ticket_id = NEW.type_of_ticket_id;

		IF num_total_tickets <= num_sold_tickets THEN
			RAISE EXCEPTION 'Unable to sell ticket. No more tickets to sell. (%) (%)', num_total_tickets, num_sold_tickets;
		END IF;
	END IF;
	RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER buy_ticket
BEFORE INSERT ON Ticket
FOR EACH ROW
EXECUTE PROCEDURE buy_ticket();



/*Delete User */

CREATE OR REPLACE FUNCTION delete_user() RETURNS TRIGGER AS
$BODY$
BEGIN
	IF tg_op = 'DELETE' THEN

		DELETE FROM Authenticated_User WHERE OLD.user_id = Authenticated_User.user_id;
		DELETE FROM Ticket WHERE OLD.user_id = Ticket.user_id;

	END IF;
	RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER delete_user
BEFORE DELETE ON Users
FOR EACH ROW
EXECUTE PROCEDURE delete_user();


/*Delete Authenticated User */

CREATE OR REPLACE FUNCTION delete_authenticated_user() RETURNS TRIGGER AS
$BODY$
BEGIN
	IF tg_op = 'DELETE' THEN

		DELETE FROM Meta_Event WHERE OLD.user_id = Meta_Event.owner_id;
		DELETE FROM Saved_Event WHERE OLD.user_id = Saved_Event.user_id;
		DELETE FROM Host WHERE OLD.user_id = Host.user_id;
		DELETE FROM Guest WHERE OLD.user_id = Guest.user_id;
		DELETE FROM Notification WHERE OLD.user_id = Notification.user_id;
		DELETE FROM Notification_Intervinient WHERE OLD.user_id = Notification_Intervinient.user_id;
		DELETE FROM JoinPoll_UnitToAuthenticated_User WHERE OLD.user_id = JoinPoll_UnitToAuthenticated_User.user_id;
		DELETE FROM Event_Content WHERE OLD.user_id = Event_Content.user_id;

	END IF;
	RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER delete_authenticated_user
BEFORE DELETE ON Authenticated_User
FOR EACH ROW
EXECUTE PROCEDURE delete_authenticated_user();


/*Delete Meta Event */

CREATE OR REPLACE FUNCTION delete_meta_event() RETURNS TRIGGER AS
$BODY$
BEGIN
	IF tg_op = 'DELETE' THEN

		DELETE FROM Saved_Event WHERE OLD.meta_event_id = Saved_Event.meta_event_id;
		DELETE FROM Host WHERE OLD.meta_event_id = Host.meta_event_id;
		DELETE FROM Event WHERE OLD.meta_event_id = Event.meta_event_id;

	END IF;
	RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER delete_meta_event
BEFORE DELETE ON Meta_Event
FOR EACH ROW
EXECUTE PROCEDURE delete_meta_event();